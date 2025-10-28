provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "jibin-s3-tfstate-bucket989"
    key    = "jibin-s3-tfstate-bucket989.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = split("/", data.aws_caller_identity.current.arn)[1]
  account_id  = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "s3_tf" {
  bucket = "jibin-s3-tf-bkt-${local.account_id}"
}
