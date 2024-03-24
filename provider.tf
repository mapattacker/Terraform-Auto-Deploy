terraform {
  backend "s3" {
    region         = "ap-southeast-1"
    bucket         = "s3-jake-terraform-state-store"
    key            = "jake/test/deploy_project/state"
    dynamodb_table = "ddb-jake-terraform-lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.42.0"
    }
  }
  required_version = ">= 1.4.5"
}


provider "aws" {
  default_tags {
    tags = {
      Agency-Code  = var.agency_code
      Terraform    = true
      Project-Code = var.project_code
      Environment  = var.env
      Requestor    = var.requestor
      Creator      = var.creator
      Repo-Name    = var.repo_name
    }
  }
}
