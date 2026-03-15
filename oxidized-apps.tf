# Cloud Run service for Oxidized Apps Website
resource "google_cloud_run_v2_service" "oxidized_apps_website" {
  name     = "oxidized-apps-website"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    # Scale to zero to minimize cost
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder - updated by CI/CD
      
      resources {
        cpu_idle = true
        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }

      ports {
        container_port = 8080
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# Allow public access to the website
resource "google_cloud_run_v2_service_iam_member" "oxidized_apps_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.oxidized_apps_website.location
  name     = google_cloud_run_v2_service.oxidized_apps_website.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Network Endpoint Group (NEG) for the Load Balancer
resource "google_compute_region_network_endpoint_group" "oxidized_apps_neg" {
  name                  = "oxidized-apps-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.oxidized_apps_website.name
  }
}

# Backend service for the website
resource "google_compute_backend_service" "oxidized_apps_backend" {
  name                  = "oxidized-apps-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.oxidized_apps_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}
