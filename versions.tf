terraform {
  required_version = ">= 1.8.0"

  # backend config for remote state (S3 + DynamoDB) can go in backend.tf
  # or you can inline here if you prefer.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}
