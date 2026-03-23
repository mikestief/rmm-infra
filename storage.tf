resource "google_storage_bucket" "receipts" {
  name     = "rmm-receipts-${var.project_id}"
  location = var.region

  # Use standard storage class
  storage_class = "STANDARD"

  # Enforce uniform bucket-level access (no ACLs)
  uniform_bucket_level_access = true

  # Prevent public access
  public_access_prevention = "enforced"

  cors {
    origin          = ["https://${var.domain}", "https://www.${var.domain}", "http://localhost:5173", "http://localhost:8080"]
    method          = ["GET", "POST", "PUT", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

output "receipts_bucket_name" {
  value = google_storage_bucket.receipts.name
}
