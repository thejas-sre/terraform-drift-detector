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
    key    = "staging/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  name                = "trade-signal-staging"
  environment         = "staging"
  region              = var.region
  cidr_block          = "10.1.0.0/16"
  public_subnet_cidr  = "10.1.1.0/24"
  private_subnet_cidr = "10.1.2.0/24"
}

module "compute" {
  source = "../../modules/compute"

  name          = "trade-signal-staging"
  environment   = "staging"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_id
}

resource "aws_s3_bucket" "drift_reports" {
  bucket = "thejas-sre-drift-reports-staging"

  tags = {
    Name        = "drift-reports-staging"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}
