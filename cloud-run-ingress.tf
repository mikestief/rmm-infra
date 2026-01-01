# Update Cloud Run UI service ingress to allow load balancer traffic
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.ui_service projects/rustymaintenance/locations/us-central1/services/rmm-ui-service

resource "google_cloud_run_v2_service" "ui_service" {
  name     = var.cloud_run_service_name
  location = var.cloud_run_service_location
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder - actual image managed by CI/CD

      # Mount Cloud SQL Unix socket
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # VPC connector for private Cloud SQL access
    vpc_access {
      connector = google_vpc_access_connector.cloud_run_connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    # Cloud SQL connection via Unix socket
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.vehicle_db.connection_name]
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
      template[0].containers[0].env,
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

# Vehicle API Cloud Run service ingress configuration
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.vehicle_api_service projects/rustymaintenance/locations/us-central1/services/rmm-vehicle-api-service

resource "google_cloud_run_v2_service" "vehicle_api_service" {
  name     = var.vehicle_api_service_name
  location = var.vehicle_api_service_location
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder - actual image managed by CI/CD

      # Mount Cloud SQL Unix socket
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # VPC connector for private Cloud SQL access
    vpc_access {
      connector = google_vpc_access_connector.cloud_run_connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    # Cloud SQL connection via Unix socket
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.vehicle_db.connection_name]
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
      template[0].containers[0].env,
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

