terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "~> 0.55.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "hcp" {
  client_secret = var.hcp_client_secret
}

provider "aws" {
  region = var.region
}
