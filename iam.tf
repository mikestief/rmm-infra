# Service Account for Vehicle API (Level 2 BFF)
# Using existing service account: rmm-vehicle-api-sa
# resource "google_service_account" "vehicle_api" {
#   account_id   = "vehicle-api-sa"
#   display_name = "Vehicle API Service Account"
# }

# Grant permissions to the Vehicle API Service Account
resource "google_storage_bucket_iam_member" "vehicle_api_storage_admin" {
  bucket = google_storage_bucket.receipts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Cloud SQL Client role to allow connection to Cloud SQL instances
resource "google_project_iam_member" "vehicle_api_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Token Creator role to allow signing URLs (self-impersonation)
resource "google_service_account_iam_member" "vehicle_api_token_creator" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Secret Manager Accessor role to fetch JWT keys and DB secrets
resource "google_project_iam_member" "vehicle_api_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Cloud SQL Instance User role for IAM Authentication login
resource "google_project_iam_member" "vehicle_api_cloudsql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Cloud Trace Agent role for OpenTelemetry
resource "google_project_iam_member" "vehicle_api_trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Vertex AI User role for Receipt Summarization
resource "google_project_iam_member" "vehicle_api_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Firebase Cloud Messaging Admin for maintenance export push notifications
resource "google_project_iam_member" "vehicle_api_firebase_messaging" {
  project = var.project_id
  role    = "roles/firebasecloudmessaging.admin"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Pub/Sub Publisher so the vehicle API can enqueue export jobs
resource "google_pubsub_topic_iam_member" "vehicle_api_export_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.vehicle_export_jobs.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Object Admin on the exports bucket for zip upload and signed URL generation
resource "google_storage_bucket_iam_member" "vehicle_api_exports_admin" {
  bucket = google_storage_bucket.exports.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Service Account for UI Service
# This identity is used by the UI BFF to call other services (Vehicle/Places APIs)
resource "google_service_account" "ui_service" {
  account_id   = "rmm-ui-service"
  display_name = "UI Service Account"
}

# Grant Secret Manager Accessor role to UI SA (for OAuth secrets and keys)
resource "google_project_iam_member" "ui_service_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.ui_service.email}"
}

# Grant Firebase Cloud Messaging Admin role to UI SA
resource "google_project_iam_member" "ui_service_firebase_messaging" {
  project = var.project_id
  role    = "roles/firebasecloudmessaging.admin"
  member  = "serviceAccount:${google_service_account.ui_service.email}"
}

# Service Account for Places API
resource "google_service_account" "places_api" {
  account_id   = "rmm-places-api-sa"
  display_name = "Places API Service Account"
}

# Grant Cloud SQL Client role to allow connection to Cloud SQL instances
resource "google_project_iam_member" "places_api_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.places_api.email}"
}

# Grant Cloud SQL Instance User role for IAM Authentication login
resource "google_project_iam_member" "places_api_cloudsql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.places_api.email}"
}

# Grant Secret Manager Accessor role to fetch JWT keys
resource "google_project_iam_member" "places_api_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.places_api.email}"
}

# Allow GitHub Actions SA to impersonate Places API SA for deployments
resource "google_service_account_iam_member" "places_api_github_actions_user" {
  service_account_id = google_service_account.places_api.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Storage Admin role to allow access to receipts bucket
resource "google_storage_bucket_iam_member" "places_api_storage_admin" {
  bucket = google_storage_bucket.receipts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.places_api.email}"
}

# Grant Token Creator role to allow signing URLs (self-impersonation)
resource "google_service_account_iam_member" "places_api_token_creator" {
  service_account_id = google_service_account.places_api.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.places_api.email}"
}

# Grant Cloud Trace Agent role for OpenTelemetry
resource "google_project_iam_member" "places_api_trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.places_api.email}"
}

# Grant Vertex AI User role for Receipt Summarization
resource "google_project_iam_member" "places_api_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.places_api.email}"
}
