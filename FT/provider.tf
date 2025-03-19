terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.55.0"  # Use a stable version
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use the latest AWS provider version
    }
  }
}

provider "hcp" {
  client_secret = var.hcp_client_secret
}

provider "aws" {
  region = var.region
}
