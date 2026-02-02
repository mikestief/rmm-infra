variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "rustymaintenance"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "domain" {
  description = "Domain name for the load balancer"
  type        = string
  default     = "rustymaintenanceman.com"
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "rmm-ui-service"
}

variable "cloud_run_service_location" {
  description = "Location of the Cloud Run service"
  type        = string
  default     = "us-central1"
}

variable "vehicle_api_service_name" {
  description = "Name of the Vehicle API Cloud Run service"
  type        = string
  default     = "rmm-vehicle-api-service"
}

variable "vehicle_api_service_location" {
  description = "Location of the Vehicle API Cloud Run service"
  type        = string
  default     = "us-central1"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-g1-small"
}

variable "db_region" {
  description = "Region for Cloud SQL instance"
  type        = string
  default     = "us-central1"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "rmm_vehicle_db"
}

variable "iap_client_id" {
  description = "OAuth2 Client ID for IAP"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iap_client_secret" {
  description = "OAuth2 Client Secret for IAP"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iap_allowed_users" {
  description = "List of users/groups/serviceAccounts/domains allowed to access the application via IAP"
  type        = list(string)
  default     = []
}

variable "cookie_secret" {
  description = "Secret used for signing cookies"
  type        = string
  sensitive   = true
}
