terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state. Enable after the state bucket in state-bucket.tf exists:
  #   1. terraform apply            (creates the bucket, state still local)
  #   2. uncomment this block
  #   3. terraform init -migrate-state
  # backend "gcs" {
  #   bucket = "rustymaintenance-terraform-state"
  #   prefix = "rmm-infra"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

