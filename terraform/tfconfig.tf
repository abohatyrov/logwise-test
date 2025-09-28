terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
  }

  required_version = ">= 1.13.0"

  backend "gcs" {
    bucket      = "logwise-test-tfstate"
    prefix      = "terraform/state"
  }
}

provider "google" {
  project     = "logwise-devops-sandbox"
  region      = "us-central1"
}

provider "google-beta" {
  project     = "logwise-devops-sandbox"
  region      = "us-central1"
}
