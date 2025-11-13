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

