# Legacy Serverless VPC Access connector.
# Cloud Run services and jobs now use Direct VPC egress. Remove this connector
# once the CI-managed migration jobs in both API repos no longer reference it.
# Using a different IP range to avoid conflicts with service networking
resource "google_vpc_access_connector" "cloud_run_connector" {
  name          = "rmm-connector-v2"
  region        = var.cloud_run_service_location
  network       = "default"
  ip_cidr_range = "10.9.0.0/28"
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3

  depends_on = [google_project_service.vpc_access]
}

