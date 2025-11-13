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

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
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

