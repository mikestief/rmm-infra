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

# Grant Secret Manager Accessor role to fetch JWT keys
resource "google_project_iam_member" "places_api_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.places_api.email}"
}
