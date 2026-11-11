# XFit gym membership tracker demo — gymtest.oxidizedapps.com
#
# Repos: mikestief/xfit-gym-api (Rust), mikestief/xfit-gym-ui (Lit + Caddy)
# PRD:   mikestief/xfit-gym-api#1
#
# Routing (on the shared global LB, see load-balancer.tf):
#   gymtest.oxidizedapps.com/api/*  -> xfit-gym-api
#   gymtest.oxidizedapps.com/*      -> xfit-gym-ui
#
# Both services only accept traffic from the load balancer and scale to zero.
# Access control is enforced in xfit-gym-api (Google OAuth + allowed_users table).
#
# DNS is NOT managed here: oxidizedapps.com DNS lives at Squarespace.
# Manual record required: gymtest  A  <LB IP, see output gymtest_lb_ip>

locals {
  gymtest_wif_principal_prefix = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/github-pool/attribute.repository"
  gymtest_github_repos         = ["mikestief/xfit-gym-api", "mikestief/xfit-gym-ui"]
  gymtest_github_actions_sa    = "projects/${var.project_id}/serviceAccounts/github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# ---------------------------------------------------------------------------
# Service accounts
# ---------------------------------------------------------------------------

resource "google_service_account" "xfit_gym_api" {
  account_id   = "xfit-gym-api-sa"
  display_name = "XFit Gym API (gymtest demo)"
}

resource "google_service_account" "xfit_gym_ui" {
  account_id   = "xfit-gym-ui-sa"
  display_name = "XFit Gym UI (gymtest demo)"
}

resource "google_project_iam_member" "xfit_gym_api_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.xfit_gym_api.email}"
}

resource "google_project_iam_member" "xfit_gym_api_cloudsql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.xfit_gym_api.email}"
}

# CI (github-actions-sa) deploys Cloud Run revisions that run as these SAs
resource "google_service_account_iam_member" "xfit_gym_api_github_actions_user" {
  service_account_id = google_service_account.xfit_gym_api.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "xfit_gym_ui_github_actions_user" {
  service_account_id = google_service_account.xfit_gym_ui.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Let GitHub Actions in the two xfit-gym repos impersonate github-actions-sa.
# The existing binding is conditioned to rmm-* repos; these are scoped to exactly these repos.
resource "google_service_account_iam_member" "xfit_gym_github_wif" {
  for_each           = toset(local.gymtest_github_repos)
  service_account_id = local.gymtest_github_actions_sa
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.gymtest_wif_principal_prefix}/${each.value}"
}

# ---------------------------------------------------------------------------
# Database (shared Cloud SQL instance, separate database)
# ---------------------------------------------------------------------------

resource "google_sql_database" "xfit_gym_db" {
  name     = "xfit_gym_db"
  instance = google_sql_database_instance.vehicle_db.name
}

resource "google_sql_user" "xfit_gym_api_sa_user" {
  name     = replace(google_service_account.xfit_gym_api.email, ".gserviceaccount.com", "")
  instance = google_sql_database_instance.vehicle_db.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

# After apply, as postgres (terraform output -raw postgres_password), connected to xfit_gym_db:
#   GRANT ALL PRIVILEGES ON DATABASE xfit_gym_db TO "xfit-gym-api-sa@rustymaintenance.iam";
#   GRANT ALL ON SCHEMA public TO "xfit-gym-api-sa@rustymaintenance.iam";

# ---------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------

# OAuth client values are added manually after creating the OAuth client in the console:
#   printf '%s' "<client id>"     | gcloud secrets versions add xfit-gym-oauth-client-id --data-file=-
#   printf '%s' "<client secret>" | gcloud secrets versions add xfit-gym-oauth-client-secret --data-file=-
#
# Both secrets were created manually (with values) before the first apply, so
# they are adopted into state with import blocks rather than created.
import {
  to = google_secret_manager_secret.xfit_gym_oauth_client_id
  id = "projects/rustymaintenance/secrets/xfit-gym-oauth-client-id"
}

import {
  to = google_secret_manager_secret.xfit_gym_oauth_client_secret
  id = "projects/rustymaintenance/secrets/xfit-gym-oauth-client-secret"
}

resource "google_secret_manager_secret" "xfit_gym_oauth_client_id" {
  secret_id = "xfit-gym-oauth-client-id"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "xfit_gym_oauth_client_secret" {
  secret_id = "xfit-gym-oauth-client-secret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secret_manager_api]
}

# Session cookie signing key (HS256), generated by Terraform
resource "random_password" "xfit_gym_session_key" {
  length  = 64
  special = false
}

resource "google_secret_manager_secret" "xfit_gym_session_key" {
  secret_id = "xfit-gym-session-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret_version" "xfit_gym_session_key" {
  secret      = google_secret_manager_secret.xfit_gym_session_key.id
  secret_data = random_password.xfit_gym_session_key.result
}

# Per-secret access for the API SA (not project-wide)
resource "google_secret_manager_secret_iam_member" "xfit_gym_api_secrets" {
  for_each = {
    oauth_client_id     = google_secret_manager_secret.xfit_gym_oauth_client_id.id
    oauth_client_secret = google_secret_manager_secret.xfit_gym_oauth_client_secret.id
    session_key         = google_secret_manager_secret.xfit_gym_session_key.id
  }
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.xfit_gym_api.email}"
}

# ---------------------------------------------------------------------------
# Cloud Run: API
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "xfit_gym_api" {
  name     = "xfit-gym-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.xfit_gym_api.email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      name  = "api"                   # CI deploys with: gcloud run services update --container=api
      image = "gcr.io/cloudrun/hello" # Placeholder - updated by CI/CD

      ports {
        container_port = 8080
      }

      resources {
        cpu_idle          = true
        startup_cpu_boost = true
        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://127.0.0.1:5432/${google_sql_database.xfit_gym_db.name}?user=xfit-gym-api-sa%40${var.project_id}.iam&sslmode=disable"
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }

      env {
        name  = "PUBLIC_BASE_URL"
        value = "https://${var.gymtest_domain}"
      }

      env {
        name  = "OAUTH_CLIENT_ID_SECRET"
        value = google_secret_manager_secret.xfit_gym_oauth_client_id.secret_id
      }

      env {
        name  = "OAUTH_CLIENT_SECRET_SECRET"
        value = google_secret_manager_secret.xfit_gym_oauth_client_secret.secret_id
      }

      env {
        name  = "SESSION_KEY_SECRET"
        value = google_secret_manager_secret.xfit_gym_session_key.secret_id
      }
    }

    # Sidecar for Cloud SQL Auth Proxy (same pattern as rmm-places-api)
    containers {
      name  = "cloud-sql-proxy"
      image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.26.0"

      args = [
        "--structured-logs",
        "--port=5432",
        "--auto-iam-authn",
        "--private-ip",
        google_sql_database_instance.vehicle_db.connection_name
      ]

      resources {
        cpu_idle          = true
        startup_cpu_boost = true
        limits = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = var.vpc_network
        subnetwork = var.vpc_subnetwork
      }
      egress = "PRIVATE_RANGES_ONLY"
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].labels,
      template[0].annotations,
      template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_iam_member.xfit_gym_api_cloudsql_client,
    google_project_iam_member.xfit_gym_api_cloudsql_instance_user,
  ]
}

# Reachable only through the LB (ingress above); app enforces Google OAuth allowlist.
resource "google_cloud_run_v2_service_iam_member" "xfit_gym_api_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.xfit_gym_api.location
  name     = google_cloud_run_v2_service.xfit_gym_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ---------------------------------------------------------------------------
# Cloud Run: UI (static Lit build served by Caddy)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "xfit_gym_ui" {
  name     = "xfit-gym-ui"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.xfit_gym_ui.email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      name  = "ui"                    # CI deploys with: gcloud run services update --container=ui
      image = "gcr.io/cloudrun/hello" # Placeholder - updated by CI/CD

      ports {
        container_port = 8080
      }

      resources {
        cpu_idle          = true
        startup_cpu_boost = true
        limits = {
          cpu    = "1"
          memory = "128Mi"
        }
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].labels,
      template[0].annotations,
      template[0].containers[0].image,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "xfit_gym_ui_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.xfit_gym_ui.location
  name     = google_cloud_run_v2_service.xfit_gym_ui.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ---------------------------------------------------------------------------
# Load balancer backends + certificate (wired into load-balancer.tf)
# ---------------------------------------------------------------------------

resource "google_compute_region_network_endpoint_group" "xfit_gym_api_neg" {
  name                  = "xfit-gym-api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.xfit_gym_api.name
  }
}

resource "google_compute_region_network_endpoint_group" "xfit_gym_ui_neg" {
  name                  = "xfit-gym-ui-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.xfit_gym_ui.name
  }
}

resource "google_compute_backend_service" "xfit_gym_api_backend" {
  name                  = "xfit-gym-api-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.xfit_gym_api_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_backend_service" "xfit_gym_ui_backend" {
  name                  = "xfit-gym-ui-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.xfit_gym_ui_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Separate cert so the existing oxidizedapps.com cert is not replaced.
# Becomes ACTIVE only after the Squarespace A record resolves to the LB IP.
resource "google_compute_managed_ssl_certificate" "gymtest" {
  name = "gymtest-oxidizedapps-ssl-cert"

  managed {
    domains = [var.gymtest_domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "gymtest_lb_ip" {
  description = "Point the gymtest A record (Squarespace) at this IP"
  value       = google_compute_global_forwarding_rule.https.ip_address
}
