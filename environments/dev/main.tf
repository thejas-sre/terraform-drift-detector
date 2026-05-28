terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "thejas-sre-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  name                = "trade-signal-dev"
  environment         = "dev"
  region              = var.region
  cidr_block          = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "compute" {
  source = "../../modules/compute"

  name          = "trade-signal-dev"
  environment   = "dev"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_id
}

resource "aws_s3_bucket" "drift_reports" {
  bucket = "thejas-sre-drift-reports-dev"

  tags = {
    Name        = "drift-reports-dev"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "drift_reports" {
  bucket = aws_s3_bucket.drift_reports.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 90
    }
  }
}
