# Cloud SQL connection name for Cloud Run
output "cloud_sql_connection_name" {
  description = "Connection name for Cloud SQL instance (used in Cloud Run)"
  value       = google_sql_database_instance.vehicle_db.connection_name
}

# Cloud SQL instance IP address
output "cloud_sql_ip_address" {
  description = "Private IP address of Cloud SQL instance"
  value       = google_sql_database_instance.vehicle_db.private_ip_address
}

# Cloud SQL instance name
output "cloud_sql_instance_name" {
  description = "Name of Cloud SQL instance"
  value       = google_sql_database_instance.vehicle_db.name
}

# Database name
output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.vehicle_db.name
}

