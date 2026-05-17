# GCS cleanup Cloud Run Jobs and their Cloud Scheduler triggers.
# These jobs periodically clean up orphaned GCS objects (e.g. receipts whose
# DB records were deleted). They run every 12 hours via Cloud Scheduler.

# ── Vehicle API cleanup job ────────────────────────────────────────────────

resource "google_cloud_run_v2_job" "vehicle_cleanup_job" {
  name     = "rmm-vehicle-gcs-cleanup-job"
  location = var.region

  deletion_protection = true

  template {
    task_count  = 1
    parallelism = 0

    template {
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      service_account       = "rmm-vehicle-api-sa@${var.project_id}.iam.gserviceaccount.com"
      max_retries           = 3
      timeout               = "600s"

      containers {
        name    = "hello-1"
        image   = "gcr.io/cloudrun/hello" # Placeholder — actual image managed by CI/CD
        command = ["./gcs-cleanup-job"]

        env {
          name  = "DATABASE_URL"
          value = "postgresql://127.0.0.1:5432/rmm_vehicle_db?user=rmm-vehicle-api-sa%40${var.project_id}.iam&sslmode=disable"
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = data.google_project.current.project_id
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "256Mi"
          }
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }

      containers {
        name  = "cloud-sql-proxy"
        image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.14.2"

        args = [
          "--structured-logs",
          "--port=5432",
          "--auto-iam-authn",
          "--private-ip",
          google_sql_database_instance.vehicle_db.connection_name,
        ]

        resources {
          limits = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.vehicle_db.connection_name]
        }
      }

      vpc_access {
        connector = google_vpc_access_connector.cloud_run_connector.id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
    ]
  }
}

# Allow the scheduler SA to invoke the vehicle cleanup job
resource "google_cloud_run_v2_job_iam_member" "vehicle_cleanup_invoker" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_job.vehicle_cleanup_job.location
  name     = google_cloud_run_v2_job.vehicle_cleanup_job.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Trigger vehicle cleanup every 12 hours via Cloud Run Job API
resource "google_cloud_scheduler_job" "vehicle_cleanup_schedule" {
  name        = "vehicle-gcs-cleanup-schedule"
  description = "Triggers the Vehicle API GCS cleanup job every 12 hours"
  schedule    = "0 */12 * * *"
  time_zone   = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.vehicle_cleanup_job.name}:run"

    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = "https://run.googleapis.com/"
    }
  }
}

# ── Places API cleanup job ─────────────────────────────────────────────────

resource "google_cloud_run_v2_job" "places_cleanup_job" {
  name     = "rmm-places-gcs-cleanup-job"
  location = var.region

  deletion_protection = true

  template {
    task_count  = 1
    parallelism = 0

    template {
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      service_account       = "rmm-places-api-sa@${var.project_id}.iam.gserviceaccount.com"
      max_retries           = 3
      timeout               = "600s"

      containers {
        name    = "hello-1"
        image   = "gcr.io/cloudrun/hello" # Placeholder — actual image managed by CI/CD
        command = ["./gcs-cleanup-job"]

        env {
          name  = "DATABASE_URL"
          value = "postgresql://127.0.0.1:5432/rmm_home_db?user=rmm-places-api-sa%40${var.project_id}.iam&sslmode=disable"
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = data.google_project.current.project_id
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "256Mi"
          }
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }

      containers {
        name  = "cloud-sql-proxy"
        image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.14.2"

        args = [
          "--structured-logs",
          "--port=5432",
          "--auto-iam-authn",
          "--private-ip",
          google_sql_database_instance.vehicle_db.connection_name,
        ]

        resources {
          limits = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.vehicle_db.connection_name]
        }
      }

      vpc_access {
        connector = google_vpc_access_connector.cloud_run_connector.id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
    ]
  }
}

# Allow the scheduler SA to invoke the places cleanup job
resource "google_cloud_run_v2_job_iam_member" "places_cleanup_invoker" {
  project  = data.google_project.current.project_id
  location = google_cloud_run_v2_job.places_cleanup_job.location
  name     = google_cloud_run_v2_job.places_cleanup_job.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Trigger places cleanup every 12 hours via Cloud Run Job API
resource "google_cloud_scheduler_job" "places_cleanup_schedule" {
  name        = "places-gcs-cleanup-schedule"
  description = "Triggers the Places API GCS cleanup job every 12 hours"
  schedule    = "0 */12 * * *"
  time_zone   = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.places_cleanup_job.name}:run"

    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = "https://run.googleapis.com/"
    }
  }
}
