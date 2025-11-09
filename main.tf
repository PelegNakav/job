terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-west-1"  # Ireland region
}

module "vpc" {
  source = "./modules/vpc"

  project_name   = var.project_name
  environment    = var.environment
  vpc_cidr      = var.vpc_cidr
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

module "ecs" {
  source = "./modules/ecs"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  container_image    = module.ecr.repository_url  # Use the ECR repository URL

  desired_count     = 2
  min_count         = 2
  max_count         = 4
  container_port    = 80
  container_memory  = 512
  container_cpu     = 256
}

