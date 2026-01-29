# Update Cloud Run UI service ingress to allow load balancer traffic
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.ui_service projects/rustymaintenance/locations/us-central1/services/rmm-ui-service

data "google_project" "current" {}

resource "google_cloud_run_v2_service" "ui_service" {
  name     = var.cloud_run_service_name
  location = var.cloud_run_service_location
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder - actual image managed by CI/CD

      # Mount Cloud SQL Unix socket
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # VPC connector for private Cloud SQL access
    vpc_access {
      connector = google_vpc_access_connector.cloud_run_connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    # Cloud SQL connection via Unix socket
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.vehicle_db.connection_name]
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
      # template[0].containers[0].env, # Managed by Terraform now
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

# Allow the External HTTP(S) Load Balancer (serverless NEG) to invoke the UI service
resource "google_cloud_run_v2_service_iam_member" "ui_invoker_lb" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.ui_service.location
  name     = google_cloud_run_v2_service.ui_service.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

# Vehicle API Cloud Run service ingress configuration
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.vehicle_api_service projects/rustymaintenance/locations/us-central1/services/rmm-vehicle-api-service

resource "google_cloud_run_v2_service" "vehicle_api_service" {
  name     = var.vehicle_api_service_name
  location = var.vehicle_api_service_location
  # Level 2 BFF: Allow all ingress but require IAM authentication.
  # Only the UI service account has roles/run.invoker, so only it can call this API.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = "rmm-vehicle-api-sa@rustymaintenance.iam.gserviceaccount.com"

    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder - actual image managed by CI/CD

      ports {
        container_port = 8080
      }

      # Environment variables
      env {
        name  = "RECEIPT_BUCKET_NAME"
        value = "rmm-receipts-${data.google_project.current.project_id}"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://127.0.0.1:5432/rmm_vehicle_db?user=rmm-vehicle-api-sa%40rustymaintenance.iam"
      }
    }

    # Sidecar for Cloud SQL Auth Proxy
    containers {
      name  = "cloud-sql-proxy"
      image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.14.2"
      
      args = [
        "--structured-logs",
        "--port=5432",
        "--auto-iam-authn",
        "--private-ip",
        google_sql_database_instance.vehicle_db.connection_name
      ]
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # VPC connector for private Cloud SQL access
    vpc_access {
      connector = google_vpc_access_connector.cloud_run_connector.id
      egress    = "PRIVATE_RANGES_ONLY"
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
      # template[0].containers[0].env, # Managed by Terraform now
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

# Level 2 BFF: Vehicle API is private; only the UI service account can invoke it.
# The UI service calls the API server-to-server using a Google-signed ID token.
resource "google_cloud_run_v2_service_iam_member" "vehicle_api_invoker_ui" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.vehicle_api_service.location
  name     = google_cloud_run_v2_service.vehicle_api_service.name

  role   = "roles/run.invoker"
  member = "serviceAccount:rmm-ui-service@${data.google_project.current.project_id}.iam.gserviceaccount.com"
}

# Places API Cloud Run service
resource "google_cloud_run_v2_service" "places_api_service" {
  name     = "rmm-places-api-service"
  location = var.region
  
  # Private service, only invoked by UI BFF
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = "rmm-places-api-sa@rustymaintenance.iam.gserviceaccount.com"

    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder

      ports {
        container_port = 8080
      }

      # Environment variables
      env {
        name  = "DATABASE_URL"
        value = "postgresql://127.0.0.1:5432/rmm_home_db?user=rmm-places-api-sa%40rustymaintenance.iam"
      }
    }

    # Sidecar for Cloud SQL Auth Proxy
    containers {
      name  = "cloud-sql-proxy"
      image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.14.2"
      
      args = [
        "--structured-logs",
        "--port=5432",
        "--auto-iam-authn",
        "--private-ip",
        google_sql_database_instance.vehicle_db.connection_name
      ]
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # VPC connector for private Cloud SQL access
    vpc_access {
      connector = google_vpc_access_connector.cloud_run_connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].labels,
      template[0].annotations,
      template[0].containers[0].image,
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

# Allow UI service to invoke Places API
resource "google_cloud_run_v2_service_iam_member" "places_api_invoker_ui" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.places_api_service.location
  name     = google_cloud_run_v2_service.places_api_service.name

  role   = "roles/run.invoker"
  member = "serviceAccount:rmm-ui-service@${data.google_project.current.project_id}.iam.gserviceaccount.com"
}
