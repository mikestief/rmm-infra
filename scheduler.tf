# Cloud Scheduler job to trigger reminder notifications hourly

# Service account for the scheduler job
resource "google_service_account" "scheduler_sa" {
  account_id   = "rmm-scheduler-sa"
  display_name = "RMM Cloud Scheduler Service Account"
}

# Allow the scheduler to invoke the UI service
resource "google_cloud_run_v2_service_iam_member" "ui_invoker_scheduler" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.ui_service.location
  name     = google_cloud_run_v2_service.ui_service.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Allow the scheduler to bypass IAP and call the UI service
# Note: google_iap_web_backend_service_iam_member is used since the UI is behind an LB with IAP
resource "google_iap_web_backend_service_iam_member" "scheduler_iap_accessor" {
  project             = data.google_project.current.project_id
  web_backend_service = google_compute_backend_service.ui_backend.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# The actual scheduler job
resource "google_cloud_scheduler_job" "reminder_notifications" {
  name        = "reminder-notifications"
  description = "Triggers the UI BFF to check and send maintenance reminders"
  schedule    = "0 * * * *" # Every hour
  time_zone   = "UTC"

  http_target {
    http_method = "POST"
    # Target the public domain to pass through the Load Balancer and IAP
    uri = "https://${var.domain}/api/v1/internal/process-reminders"

    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      # For IAP specifically, the audience MUST be the Client ID of the IAP OAuth client
      audience = var.iap_client_id
    }
  }
}
