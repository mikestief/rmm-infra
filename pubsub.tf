# Pub/Sub infrastructure for async vehicle maintenance export jobs.
#
# Flow:
#   trigger_export handler  →  vehicle_export_jobs topic
#     → vehicle_export_processor subscription (push → /process)
#       on failure (5 attempts) → vehicle_export_jobs_dlq topic
#         → vehicle_export_dlq subscription (push → /process-dlq)

# ── Topics ─────────────────────────────────────────────────────────────────

resource "google_pubsub_topic" "vehicle_export_jobs" {
  name    = "rmm-vehicle-export-jobs"
  project = var.project_id

  depends_on = [google_project_service.pubsub_api]
}

resource "google_pubsub_topic" "vehicle_export_jobs_dlq" {
  name    = "rmm-vehicle-export-jobs-dlq"
  project = var.project_id

  depends_on = [google_project_service.pubsub_api]
}

# ── Service account for Pub/Sub push auth ──────────────────────────────────
#
# Pub/Sub signs each push request with an OIDC token from this SA.
# The vehicle API's internal_auth_middleware validates that token.

resource "google_service_account" "pubsub_export_invoker" {
  account_id   = "rmm-pubsub-export-invoker"
  display_name = "Pub/Sub Export Job Invoker"
}

# Pub/Sub service agent needs token-creator on the invoker SA so it can
# mint OIDC tokens when delivering push messages.
resource "google_service_account_iam_member" "pubsub_sa_token_creator" {
  service_account_id = google_service_account.pubsub_export_invoker.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Allow the invoker SA to call the (private) vehicle API Cloud Run service.
resource "google_cloud_run_v2_service_iam_member" "vehicle_api_invoker_pubsub" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.vehicle_api_service.location
  name     = google_cloud_run_v2_service.vehicle_api_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_export_invoker.email}"
}

# ── DLQ IAM (Pub/Sub service agent needs publish + subscribe rights) ────────

resource "google_pubsub_topic_iam_member" "pubsub_sa_dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.vehicle_export_jobs_dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "pubsub_sa_main_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.vehicle_export_processor.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# ── Subscriptions ──────────────────────────────────────────────────────────

resource "google_pubsub_subscription" "vehicle_export_processor" {
  name    = "rmm-vehicle-export-processor"
  topic   = google_pubsub_topic.vehicle_export_jobs.name
  project = var.project_id

  # Give the handler up to 10 minutes to process a zip build + upload.
  ack_deadline_seconds = 600

  # Keep undelivered messages for 1 hour (exports expire quickly).
  message_retention_duration = "3600s"

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "300s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.vehicle_export_jobs_dlq.id
    max_delivery_attempts = 5
  }

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.vehicle_api_service.uri}/api/v1/internal/vehicles/maintenance/export/process"

    oidc_token {
      service_account_email = google_service_account.pubsub_export_invoker.email
      audience              = google_cloud_run_v2_service.vehicle_api_service.uri
    }
  }
}

resource "google_pubsub_subscription" "vehicle_export_dlq" {
  name    = "rmm-vehicle-export-dlq"
  topic   = google_pubsub_topic.vehicle_export_jobs_dlq.name
  project = var.project_id

  ack_deadline_seconds       = 60
  message_retention_duration = "86400s"

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.vehicle_api_service.uri}/api/v1/internal/vehicles/maintenance/export/process-dlq"

    oidc_token {
      service_account_email = google_service_account.pubsub_export_invoker.email
      audience              = google_cloud_run_v2_service.vehicle_api_service.uri
    }
  }
}

# ── Google Play Real-time Developer Notifications ──────────────────────────
#
# Flow:
#   Google Play  →  rmm-play-notifications topic (push subscription)
#     → BFF /api/webhooks/google?token=<secret> → upserts user_subscriptions
#       on failure (5 attempts) → rmm-play-notifications-dead-letter topic
#
# Verification: BFF checks ?token query param against GOOGLE_PLAY_PUBSUB_TOKEN
# env var (value loaded into Secret Manager as google-play-pubsub-token).
# No OIDC token needed — Google Play pushes to a public HTTPS endpoint.

resource "google_pubsub_topic" "play_notifications" {
  name    = "rmm-play-notifications"
  project = var.project_id

  depends_on = [google_project_service.pubsub_api]
}

resource "google_pubsub_topic" "play_notifications_dlq" {
  name    = "rmm-play-notifications-dead-letter"
  project = var.project_id

  depends_on = [google_project_service.pubsub_api]
}

# DLQ IAM: Pub/Sub service agent needs publish rights on DLQ topic
# and subscribe rights on the source subscription to move failed messages.
resource "google_pubsub_topic_iam_member" "pubsub_sa_play_dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.play_notifications_dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "pubsub_sa_play_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.play_notifications_push.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription" "play_notifications_push" {
  name    = "rmm-play-notifications-push"
  topic   = google_pubsub_topic.play_notifications.name
  project = var.project_id

  ack_deadline_seconds       = 20
  message_retention_duration = "86400s"

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.play_notifications_dlq.id
    max_delivery_attempts = 5
  }

  push_config {
    # Token verified by BFF against GOOGLE_PLAY_PUBSUB_TOKEN env var.
    # Update this value (re-apply) if the token is rotated.
    push_endpoint = "https://app.rustymaintenance.com/api/webhooks/google?token=${var.google_play_pubsub_token}"
  }
}

# ── Outputs ────────────────────────────────────────────────────────────────

output "vehicle_export_topic_id" {
  description = "Full resource ID of the vehicle export Pub/Sub topic (set as PUBSUB_EXPORT_TOPIC env var)"
  value       = google_pubsub_topic.vehicle_export_jobs.id
}

output "pubsub_export_invoker_email" {
  description = "Service account email for Pub/Sub push auth (set as PUBSUB_SA_EMAIL env var)"
  value       = google_service_account.pubsub_export_invoker.email
}
