# AWS ECS Infrastructure with CI/CD Pipeline

This project sets up a complete AWS infrastructure for running containerized applications on ECS (Elastic Container Service) with automated CI/CD using GitHub Actions. It's built with Terraform and follows best practices for security, scalability, and monitoring.

## What This Does

This infrastructure deploys:
- A VPC with public and private subnets across multiple availability zones
- An ECS Fargate cluster running your containerized application
- An Application Load Balancer (ALB) for internet access
- Auto-scaling based on CPU utilization
- CloudWatch monitoring and alarms
- An ECR repository for storing Docker images
- A complete CI/CD pipeline that automatically builds and deploys on code changes

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (>= 1.0)
- A GitHub repository with the code
- An IAM role in AWS for GitHub Actions (I created one manually called `github-peleg`)

### Initial Setup

1. **Clone the repository and navigate to the project directory**

2. **Initialize and deploy the infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

   This will create the entire cloud environment, but **the ECS service won't work yet** because there are no images in ECR at this point.

3. **Set up GitHub Actions secrets:**
   - Go to your GitHub repository settings
   - Add a secret named `AWS_ROLE_ARN` with the ARN of your GitHub IAM role (the one called `github-peleg`)

4. **Trigger the CI/CD pipeline:**
   - Push changes to the `app/` directory or the workflow file
   - GitHub Actions will automatically:
     - Build your Docker image
     - Push it to ECR
     - Deploy it to your ECS service


## Architecture Overview

The infrastructure is organized into three Terraform modules:

### 1. VPC Module (`modules/vpc/`)

This module creates the networking foundation:
- **VPC** with a CIDR block (default: `10.0.0.0/16`)
- **4 Subnets** split across 2 availability zones:
  - 2 public subnets for the Application Load Balancer
  - 2 private subnets for ECS tasks (containers)
- **Internet Gateway** for public internet access
- **NAT Gateway** (one per AZ) so private subnets can reach the internet for pulling images
- **Route tables** properly configured for public and private subnets
- **VPC Endpoints** for secure, private communication with AWS services:
  - ECR API endpoint (for pulling images)
  - ECR DKR endpoint (Docker registry)
  - CloudWatch Logs endpoint (for sending logs)
  - S3 Gateway endpoint (available for future use, though not currently used in this project)

**Why VPC Endpoints?** Since ECS tasks run in private subnets without direct internet access, VPC endpoints allow them to communicate with AWS services (like ECR and CloudWatch) without going through the internet. This improves security and can reduce costs compared to NAT Gateway data transfer.

### 2. ECR Module (`modules/ecr/`)

This module sets up the container registry:
- **ECR Repository** for storing Docker images
- **Image scanning** enabled for security
- **Lifecycle policy** that keeps the last 30 images (automatically cleans up old ones)
- **Repository policy** that allows ECS to pull images

### 3. ECS Module (`modules/ecs/`)

This is the heart of the application infrastructure:
- **ECS Cluster** with Container Insights enabled for monitoring
- **ECS Service** running on Fargate (serverless containers)
- **Task Definition** with CPU, memory, and container configuration
- **Application Load Balancer** (ALB) that exposes the app to the internet
- **Target Group** with health checks
- **Auto Scaling** configured to:
  - Maintain at least 2 running tasks
  - Scale up to 4 tasks when CPU utilization exceeds 80%
  - Scale down when CPU drops
- **Security Groups**:
  - ALB security group (allows HTTP traffic from internet)
  - ECS tasks security group (only allows traffic from ALB)
- **CloudWatch Logs** for container logs (30-day retention)
- **SNS Topic** for alarm notifications
- **CloudWatch Alarm** that monitors the running task count and alerts when it's not exactly 2 tasks

## Monitoring & Alarms

The infrastructure includes comprehensive monitoring:

- **CloudWatch Logs**: All container logs are automatically sent to CloudWatch with a 30-day retention period
- **Container Insights**: Enabled on the ECS cluster for detailed metrics
- **CloudWatch Alarm**: Monitors the running task count and sends an email alert via SNS when the count deviates from the expected value (currently set to 2 tasks)



## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:

1. **Builds** the Docker image from the `app/` directory
2. **Pushes** it to ECR with two tags:
   - A unique tag based on the Git commit SHA
   - A `latest` tag
3. **Updates** the ECS task definition with the new image
4. **Deploys** the new task definition to the ECS service
5. **Waits** for the service to stabilize before completing

The pipeline triggers on:
- Pushes to the `main` branch that affect files in `app/` or the workflow file
- Pull requests to `main` (for testing)

## Project Structure

```
.
├── main.tf                 # Root module that ties everything together
├── variables.tf            # Root-level variables
├── terraform.tfvars       # Your configuration values
├── modules/
│   ├── vpc/               # VPC, subnets, networking
│   │   ├── main.tf
│   │   ├── vpc_endpoints.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/               # Container registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecs/               # ECS cluster, service, ALB, monitoring
│       ├── main.tf
│       ├── iam.tf         # IAM roles for ECS
│       ├── data.tf        # Data sources
│       ├── variables.tf
│       └── outputs.tf
├── app/                   # Your application code
│   ├── Dockerfile
│   └── index.html
└── .github/
    └── workflows/
        └── deploy.yml     # CI/CD pipeline
```

## Configuration

Key variables you can customize in `terraform.tfvars`:

- `project_name`: Used for naming all resources
- `environment`: Environment tag (dev/staging/prod)
- `vpc_cidr`: VPC CIDR block
- `public_subnet_cidrs`: CIDR blocks for public subnets
- `private_subnet_cidrs`: CIDR blocks for private subnets
- `availability_zones`: AWS availability zones to use
- `region`: AWS region

ECS-specific settings are in `main.tf`:
- `desired_count`: Number of tasks to run (default: 2)
- `min_count` / `max_count`: Auto-scaling limits
- `container_cpu` / `container_memory`: Resource allocation
- `container_port`: Port your app listens on

## Getting the Application URL

After deployment, get your ALB DNS name:

```bash
terraform output alb_dns_name
```

Then visit `http://<alb-dns-name>` in your browser. The ALB listens on port 80 (HTTP).

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: Make sure to empty the ECR repository first if you want to avoid errors:
```bash
aws ecr list-images --repository-name peleg-repo --query 'imageIds[*]' --output json | \
  jq -r '.[] | "\(.imageDigest)"' | \
  xargs -I {} aws ecr batch-delete-image --repository-name peleg-repo --image-ids imageDigest={}
```
if the repo isnt empty it will not be destroyed with terraform destroy
## Notes


- The GitHub Actions IAM role (`github-peleg`) was created manually
- The alarm is currently configured to alert when the running task count is not exactly 2

## Original Requirements

This project was built to fulfill the following requirements:

1. ✅ AWS infrastructure automation with Terraform
   - VPC with Internet Gateway
   - 4 Subnets (2 public, 2 private)
   - Proper networking configuration

2. ✅ ECS deployment
   - "Hello World" container on ECS cluster
   - Service Auto Scaling (2+ running tasks)
   - Application Load Balancer with internet access
   - Tasks in private subnets
   - Monitoring and alarms for container errors

3. ✅ CI/CD pipeline
   - GitHub Actions automation
   - Automatic Docker image build and push to ECR
   - Automatic ECS deployment on code changes
