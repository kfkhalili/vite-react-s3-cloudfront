terraform {
  required_version = ">= 1.6.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.31.0"
    }
  }
  backend "local" {
    path = "./1.terraform.tfstate"
  }
}
provider "aws" {
  region = "${var.aws_region}"
}

variable "app_name" { type=string } 
variable "aws_region" { type=string } 

# Set bucket value
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.app_name}-terraform-state-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}