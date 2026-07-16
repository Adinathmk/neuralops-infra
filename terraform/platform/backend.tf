terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "neuralops-terraform-state-160823835768"
    key            = "platform/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "neuralops-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "neuralops"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
