terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      version = ">= 5.100.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.common_tags.Env
      Owner       = var.common_tags.Owner
      Project     = var.common_tags.Project
      Name        = var.common_tags.Name
    }
  }
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy to (ensure your AMIs are registered there)"
  default     = "eu-north-1"
}