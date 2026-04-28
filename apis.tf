# Enable required APIs for private Cloud SQL and VPC connector
resource "google_project_service" "service_networking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "vpc_access" {
  project = var.project_id
  service = "vpcaccess.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "sql_component" {
  project = var.project_id
  service = "sql-component.googleapis.com"

  disable_on_destroy = false
}

# GCS and IAM Credentials for Receipt functionality
resource "google_project_service" "storage_api" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_credentials" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

# Places API
resource "google_project_service" "places_api" {
  project            = var.project_id
  service            = "places.googleapis.com"
  disable_on_destroy = false
}

# Cloud Trace API for OpenTelemetry
resource "google_project_service" "cloud_trace_api" {
  project            = var.project_id
  service            = "cloudtrace.googleapis.com"
  disable_on_destroy = false
}

# Vertex AI API for Gemini 1.5 Flash
resource "google_project_service" "aiplatform_api" {
  project            = var.project_id
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

# Cloud Scheduler API for maintenance reminders
resource "google_project_service" "cloud_scheduler_api" {
  project            = var.project_id
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

# Pub/Sub API for async maintenance export jobs
resource "google_project_service" "pubsub_api" {
  project            = var.project_id
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Firebase Cloud Messaging API for push notifications
resource "google_project_service" "fcm_api" {
  project            = var.project_id
  service            = "fcm.googleapis.com"
  disable_on_destroy = false
}
