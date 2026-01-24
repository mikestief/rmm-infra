# Update Cloud Run UI service ingress to allow load balancer traffic
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.ui_service projects/rustymaintenance/locations/us-central1/services/rmm-ui-service

data "google_project" "current" {}

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
      client,
      client_version,
      template[0].labels,
      template[0].annotations,
      template[0].containers[0].image,
      template[0].containers[0].env,
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

# Allow the External HTTP(S) Load Balancer (serverless NEG) to invoke the UI service
resource "google_cloud_run_v2_service_iam_member" "ui_invoker_lb" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.ui_service.location
  name     = google_cloud_run_v2_service.ui_service.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

# Vehicle API Cloud Run service ingress configuration
# Note: This assumes the Cloud Run service already exists.
# If you need to import it, run:
# terraform import google_cloud_run_v2_service.vehicle_api_service projects/rustymaintenance/locations/us-central1/services/rmm-vehicle-api-service

resource "google_cloud_run_v2_service" "vehicle_api_service" {
  name     = var.vehicle_api_service_name
  location = var.vehicle_api_service_location
  # Level 2 BFF: Allow all ingress but require IAM authentication.
  # Only the UI service account has roles/run.invoker, so only it can call this API.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.vehicle_api.email

    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder - actual image managed by CI/CD

      # Mount Cloud SQL Unix socket
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Environment variables
      env {
        name  = "RECEIPT_BUCKET_NAME"
        value = "rmm-receipts-${data.google_project.current.project_id}"
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
      client,
      client_version,
      template[0].labels,
      template[0].annotations,
      template[0].containers[0].image,
      template[0].containers[0].env,
      template[0].containers[0].resources,
      template[0].containers[0].ports,
      template[0].containers[0].args,
      template[0].containers[0].command,
    ]
  }
}

# Level 2 BFF: Vehicle API is private; only the UI service account can invoke it.
# The UI service calls the API server-to-server using a Google-signed ID token.
resource "google_cloud_run_v2_service_iam_member" "vehicle_api_invoker_ui" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_service.vehicle_api_service.location
  name     = google_cloud_run_v2_service.vehicle_api_service.name

  role   = "roles/run.invoker"
  member = "serviceAccount:rmm-ui-service@${data.google_project.current.project_id}.iam.gserviceaccount.com"
}
