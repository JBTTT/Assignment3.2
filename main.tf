provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "jibin-s3.1-bucket989"
    key    = "jibin-s3.1-bucket989.tfstate"
    region = "us-east-1"
  }
}
