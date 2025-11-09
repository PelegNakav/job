# AWS ECS Application Infrastructure

This project implements a containerized "Hello World" application deployed on AWS ECS with a focus on AWS Well-Architected Framework pillars.

## Infrastructure Overview

The infrastructure is built using Terraform and consists of:
- VPC with public and private subnets
- ECS Fargate cluster
- Application Load Balancer
- ECR repository
- CI/CD pipeline using GitHub Actions

## AWS Well-Architected Framework Pillars

### 1. Operational Excellence
- **Infrastructure as Code (IaC)**: Using Terraform for infrastructure management
- **CI/CD Pipeline**: Automated deployment pipeline using GitHub Actions
- **Monitoring**: CloudWatch Container Insights enabled for ECS cluster
- **Logging**: Centralized logging with CloudWatch Logs
- **Version Control**: All infrastructure and application code in Git

### 2. Security
- **Network Security**:
  - VPC with public and private subnets
  - Private subnets for ECS tasks
  - Security groups restricting access
  - VPC Endpoints for secure ECR access
- **Identity and Access Management**:
  - IAM roles with least privilege principle
  - Task execution roles for ECS
  - ECR repository policies
- **Data Protection**:
  - ECR image scanning enabled
  - HTTPS for ALB listeners
  - Private container registry (ECR)

### 3. Reliability
- **High Availability**:
  - Multi-AZ deployment across 2 availability zones
  - Load balancer for traffic distribution
  - Auto Scaling for ECS tasks
- **Fault Tolerance**:
  - Health checks configured
  - Task auto-recovery
  - Service auto-scaling
- **Disaster Recovery**:
  - Infrastructure defined as code
  - Container images versioned in ECR

### 4. Performance Efficiency
- **Compute**:
  - Serverless containers with Fargate
  - Right-sized container resources
  - Auto-scaling based on demand
- **Networking**:
  - Application Load Balancer
  - VPC endpoints for optimal ECR access
  - Private subnets for container tasks
- **Monitoring**:
  - CloudWatch metrics
  - Container insights
  - ALB access logs

### 5. Cost Optimization
- **Resource Optimization**:
  - Fargate Spot (optional) for cost savings
  - Auto-scaling for efficient resource use
  - Right-sized task definitions
- **Cost Monitoring**:
  - CloudWatch metrics for resource utilization
  - Cost allocation tags
- **Architecture Optimization**:
  - Serverless containers to eliminate EC2 management
  - Multi-AZ without over-provisioning

## Infrastructure Components

### VPC Configuration
- CIDR: 10.0.0.0/16
- 2 Public Subnets
- 2 Private Subnets
- Internet Gateway
- VPC Endpoints for ECR and S3

### ECS Configuration
- Fargate Launch Type
- Service Auto Scaling (min: 2, max: 4)
- Container Insights Enabled
- CloudWatch Logging

### ECR Configuration
- Image Scanning on Push
- Lifecycle Rules
- Repository Policy

## CI/CD Pipeline

### GitHub Actions Workflow
1. Build Container Image
2. Push to ECR
3. Update ECS Task Definition
4. Deploy to ECS Service

### Security Considerations
- OIDC authentication with AWS
- Least privilege IAM roles
- Secure secrets management

## Getting Started

1. Clone the repository
2. Configure AWS credentials
3. Create GitHub repository secrets:
   - AWS_ROLE_ARN
4. Deploy infrastructure:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Monitoring and Maintenance

### Monitoring
- CloudWatch Container Insights
- ALB Access Logs
- Container Logs

### Alerting
- CloudWatch Alarms for:
  - Container Errors
  - High CPU/Memory Usage
  - Failed Health Checks

## Best Practices

- Use semantic versioning for container images
- Implement proper tagging strategy
- Regular security updates
- Monitor and optimize costs
- Regular backup and disaster recovery tests

## Future Improvements

1. Implement Blue/Green Deployments
2. Add WAF for ALB Protection
3. Implement Cross-Region Disaster Recovery
4. Add Service Mesh (AWS App Mesh)
5. Implement Automated Testing in CI/CD

## License

This project is licensed under the MIT License - see the LICENSE file for details.