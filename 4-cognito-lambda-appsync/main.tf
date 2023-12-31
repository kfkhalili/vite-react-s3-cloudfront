terraform {
  required_version = ">= 1.6.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.31.0"
    }
  }
  backend "s3" {
    key = "4.terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {}

locals {
  app_name_with_spaces = replace(var.app_name, "-", " ")
  app_name_title_case = title(local.app_name_with_spaces)
  app_name_title_case_together = replace(local.app_name_title_case, " ", "")
  app_name_lower_camel_case = "${lower(substr(local.app_name_title_case_together, 0, 1))}${substr(local.app_name_title_case_together, 1, length(local.app_name_title_case_together))}"
}