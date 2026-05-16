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
    origin          = ["https://${var.domain}", "https://www.${var.domain}", "http://localhost:5173", "http://localhost:8080", "capacitor://localhost"]
    method          = ["GET", "POST", "PUT", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

output "receipts_bucket_name" {
  value = google_storage_bucket.receipts.name
}

# Bucket for maintenance history export zip files.
# Objects are automatically deleted after 30 days — exports are short-lived
# downloads delivered via 24-hour signed URLs.
resource "google_storage_bucket" "exports" {
  name     = "rmm-exports-${var.project_id}"
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}

output "exports_bucket_name" {
  description = "GCS bucket for maintenance export zips (set as EXPORT_BUCKET_NAME env var)"
  value       = google_storage_bucket.exports.name
}
