terraform {
    required_providers {
      aws = {
          source   = "hashicorp/aws"
          version  = ">=3.63"
      }
  }
  required_version = ">=0.13.1"
}