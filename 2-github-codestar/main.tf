terraform {
  required_version = ">= 1.6.6"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5.42.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.31.0"
    }
  }
  backend "s3" {
    key = "2.terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

provider "github" {
  token = var.github_token
}