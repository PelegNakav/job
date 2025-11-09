# Example values for your infrastructure
project_name = "peleg"
environment  = "dev"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Subnet Configuration
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# Update these with your desired AZs
availability_zones = ["eu-west-1a", "eu-west-1b"]