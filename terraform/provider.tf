terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region = "us-east-2"  # You can change this to your preferred region
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "tech-challenge-2"
      ManagedBy   = "terraform"
    }
  }
}