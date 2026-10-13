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

  # Remote state in the versioned bucket defined in state-bucket.tf.
  # The bucket is itself managed by this configuration, so never destroy the
  # whole stack; it also has prevent_destroy set.
  backend "gcs" {
    bucket = "rustymaintenance-terraform-state"
    prefix = "rmm-infra"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

