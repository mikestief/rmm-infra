# Update Cloud Run service ingress to allow load balancer traffic
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.default projects/rustymaintenance/locations/us-central1/services/rmm-ui-service

resource "google_cloud_run_v2_service" "default" {
  name     = var.cloud_run_service_name
  location = var.cloud_run_service_location
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    # Preserve existing container configuration
    # The actual image and other settings should be managed via CI/CD
    # This resource primarily manages the ingress setting
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

