# REF https://registry.terraform.io/providers/hashicorp/google/latest/docs
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
# Credentials only needs to be set if you do not have the GOOGLE_APPLICATION_CREDENTIALS set
# credentials = file("path/to/your/credentials.json")
  project = "dtc-de-448310"
  region  = "us-central1"
}


# REF: Example Usage - Life cycle settings for storage bucket objects
# https://registry.terraform.io/providers/wiardvanrij/ipv4google/latest/docs/resources/storage_bucket

resource "google_storage_bucket" "data-lake-bucket" {
  name          = "<Your Unique Bucket Name>" // needs to be globally unique!
  location      = "US"

  # Optional, but recommended settings:
  # storage class determines cost and performance characteristics
  storage_class = "STANDARD" # for high-performance, frequently accessed data
  
  # to manage permissions at the bucket level rather than the object level:
  uniform_bucket_level_access = true

# Enables object versioning for the bucket (Keeps older versions of objects when they are overwritten or delete)
  versioning {
    enabled     = true
  }

# defines automated rules for managing the lifecycle of objects within the bucket
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  // days
    }
  }

  # Ensures that Terraform can delete the bucket even if it contains objects:
  force_destroy = true
}

# p.s. In Google Cloud Storage, a bucket is a container for storing objects (files)


resource "google_bigquery_dataset" "dataset" {
  dataset_id = "<The Dataset Name You Want to Use>" // unique within your GCP project
  project    = "<Your Project ID>"
  location   = "US"
}