terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "sctp-ce11-tfstate"
    key    = "jibin-s3-tfstate.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  prefix     = "<your-prefix>"
  account_id = data.aws_caller_identity.current.account_id
}

# --- Logging bucket (target for access logs) ---
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${local.prefix}-s3-logs-${local.account_id}"
}

resource "aws_s3_bucket_public_access_block" "log_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# --- Main bucket ---
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${local.prefix}-secure-bucket-${local.account_id}"

  tags = {
    Name        = "Secure S3 Bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_block" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "secure_ver" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_logging" "secure_logging" {
  bucket        = aws_s3_bucket.secure_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "access-logs/"
}

# --- HTTPS-only access policy ---
resource "aws_s3_bucket_policy" "https_only" {
  bucket = aws_s3_bucket.secure_bucket.id

policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Sid       = "EnforceTLS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.secure_bucket.arn,
        format("%s/*", aws_s3_bucket.secure_bucket.arn)
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }
  ]
})
}