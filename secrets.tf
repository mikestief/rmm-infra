# Secret Manager resource shells for subscription billing.
#
# These resources create the named secret containers only — no values.
# Secret values are loaded separately via:
#   gcloud secrets versions add <name> --data-file=- --project=rustymaintenance
#
# The rmm-ui Cloud Run service already has roles/secretmanager.secretAccessor
# at project level (see iam.tf) and can access all secrets here.

resource "google_secret_manager_secret" "apple_appstore_key_id" {
  secret_id  = "apple-appstore-key-id"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "apple_appstore_issuer_id" {
  secret_id  = "apple-appstore-issuer-id"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "apple_appstore_private_key" {
  secret_id  = "apple-appstore-private-key"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "apple_root_ca_cert" {
  secret_id  = "apple-root-ca-cert"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "google_play_service_account_json" {
  secret_id  = "google-play-service-account-json"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "google_play_pubsub_token" {
  secret_id  = "google-play-pubsub-token"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "stripe_secret_key" {
  secret_id  = "stripe-secret-key"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "stripe_webhook_secret" {
  secret_id  = "stripe-webhook-secret"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}

resource "google_secret_manager_secret" "stripe_customer_portal_config_id" {
  secret_id  = "stripe-customer-portal-config-id"
  project    = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager_api]
}
