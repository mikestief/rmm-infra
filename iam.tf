resource "google_service_account" "vehicle_api" {
  account_id   = "vehicle-api-sa"
  display_name = "Vehicle API Service Account"
}

# Grant permissions to the Vehicle API Service Account
resource "google_storage_bucket_iam_member" "vehicle_api_storage_admin" {
  bucket = google_storage_bucket.receipts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vehicle_api.email}"
}
