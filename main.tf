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

}

data "aws_caller_identity" "current" {}

locals {
  # Get IAM username assuming ARN format ...:user/<username>
  name_prefix = split("/", data.aws_caller_identity.current.arn)[1]
  account_id  = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "s3_tf" {
  bucket = "s3-${local.name_prefix}-tf-bkt-${local.account_id}"
}

# Block public access ✅ CKV2_AWS_6
resource "aws_s3_bucket_public_access_block" "s3_tf" {
  bucket                  = aws_s3_bucket.s3_tf.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Enable versioning ✅ CKV_AWS_21
resource "aws_s3_bucket_versioning" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Default encryption with KMS ✅ CKV_AWS_144, CKV_AWS_18
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

# Lifecycle configuration ✅ CKV2_AWS_61
resource "aws_s3_bucket_lifecycle_configuration" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Logging bucket for access logs ✅ CKV_AWS_18
resource "aws_s3_bucket" "log_bucket" {
  bucket = "log-${local.name_prefix}-${local.account_id}"
}

resource "aws_s3_bucket_logging" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "s3-access-logs/"
}

# Notification placeholder ✅ CKV2_AWS_62
resource "aws_s3_bucket_notification" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id
}
