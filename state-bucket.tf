# Bucket for Terraform remote state (see the backend block in main.tf).
# Object versioning keeps prior state revisions for recovery.
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-terraform-state"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # Keep the 30 most recent prior versions of each state object.
  lifecycle_rule {
    condition {
      num_newer_versions = 30
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
