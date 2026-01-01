# Cloud SQL PostgreSQL instance for vehicle API
resource "google_sql_database_instance" "vehicle_db" {
  name             = "rmm-vehicle-db-instance"
  database_version = "POSTGRES_15"
  region           = var.db_region

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sql_component,
  ]

  settings {
    tier                        = var.db_tier
    deletion_protection_enabled = false

    # Minimal backup configuration for cost savings
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = false
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # IP configuration - private IP only for secure access
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = "projects/${var.project_id}/global/networks/default"
      enable_private_path_for_google_cloud_services = true
    }

    # Database flags for optimization
    database_flags {
      name  = "max_connections"
      value = "25" # db-f1-micro has limited connections
    }

    # Minimal maintenance window
    maintenance_window {
      day          = 7 # Sunday
      hour         = 4
      update_track = "stable"
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# IAM role binding for Cloud SQL client access
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "user:dstief1980@gmail.com"
}

