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
    bucket = "jibin-s3-tfstate-bucket989"
    key    = "jibin-s3-tfstate-bucket989.tfstate"
    region = "us-east-1"
  }

}

#data "aws_caller_identity" "current" {}

#locals {
#  name_prefix = split("/", data.aws_caller_identity.current.arn)[1]
#  account_id  = data.aws_caller_identity.current.account_id
#}

resource "aws_s3_bucket" "s3_tf" {
  bucket = "jibin-s3-tf-bkt9889"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.jibin-s3-tf-bkt9889
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
