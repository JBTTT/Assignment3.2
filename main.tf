provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "sctp-ce11-tfstate"
    key    = "jibin-s3-tfstate.tfstate"
    region = "us-east-1"
  }


# Create an S3 bucket
resource "aws_s3_bucket" "simple_bucket" {
  bucket = "jibin-assignment3.2-s3bucket"
}
}