# Database within the Cloud SQL instance
resource "google_sql_database" "vehicle_db" {
  name     = var.db_name
  instance = google_sql_database_instance.vehicle_db.name
}

# Database user (optional - can use Cloud SQL IAM authentication instead)
# Uncomment if you need a password-based user
# resource "google_sql_user" "vehicle_db_user" {
#   name     = "vehicle_api_user"
#   instance = google_sql_database_instance.vehicle_db.name
#   password = var.db_password # Store in Secret Manager or use random_password
# }

