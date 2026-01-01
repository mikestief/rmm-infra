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

# Random password for postgres superuser
resource "random_password" "postgres_password" {
  length  = 32
  special = true
}

# Postgres superuser - manages password for administrative access
resource "google_sql_user" "postgres" {
  name     = "postgres"
  instance = google_sql_database_instance.vehicle_db.name
  password = random_password.postgres_password.result
}

# IAM database user for dstief1980@gmail.com
resource "google_sql_user" "iam_user" {
  name     = "dstief1980@gmail.com"
  instance = google_sql_database_instance.vehicle_db.name
  type     = "CLOUD_IAM_USER"
}

# Grant database privileges to IAM user
# After running terraform apply, connect as postgres user using the password from output
# Run: terraform output -raw postgres_password
# Then connect and run these SQL commands:
# GRANT ALL PRIVILEGES ON DATABASE rmm_vehicle_db TO "dstief1980@gmail.com";
# GRANT ALL ON SCHEMA public TO "dstief1980@gmail.com";
# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "dstief1980@gmail.com";
# GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "dstief1980@gmail.com";
# ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "dstief1980@gmail.com";
# ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "dstief1980@gmail.com";

