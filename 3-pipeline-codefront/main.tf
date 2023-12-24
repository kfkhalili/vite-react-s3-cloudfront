terraform {
  required_version = ">= 1.6.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.31.0"
    }
  }
  backend "s3" {
    key = "3.terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {}
