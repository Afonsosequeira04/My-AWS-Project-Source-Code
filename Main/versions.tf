# This file is part of the Terraform configuration for managing AWS resources using the AWS provider.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

