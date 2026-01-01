terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Uncomment and configure backend after creating GCS bucket
  # backend "gcs" {
  #   bucket = "rustymaintenance-terraform-state"
  #   prefix = "rmm-infra"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

