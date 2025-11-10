# AWS ECS Application Infrastructure

Production-ready containerized app infrastructure on AWS. Built with Terraform and follows AWS Well-Architected Framework principles.

## Architecture Overview

Here's the basic flow:

```
Internet → Application Load Balancer (public) → ECS Fargate Tasks (private)
                                                      ↓
                                              ECR, CloudWatch, VPC Endpoints
```

Users hit the load balancer, which routes traffic to containers running in private subnets. Those containers pull images from ECR and send logs to CloudWatch, all through VPC endpoints so they don't need internet access.

## AWS Services

### VPC

Your private network in AWS. Think of it as your own isolated section of the cloud.

We set up public subnets (for the load balancer) and private subnets (for containers). The private subnets don't have direct internet access, which is good for security. Containers live there and can't be reached directly from the internet.

The VPC also has route tables that control where traffic goes, and an internet gateway so the public subnets can actually reach the internet.

### ECS (Elastic Container Service)

This is where we run Docker containers. We're using Fargate, which means AWS manages the servers for us - we just define what containers we want and ECS handles the rest.

The cluster is just a logical grouping. The task definition is like a blueprint - it says "run this image with this much CPU and memory." The service keeps those tasks running and scales them up or down based on demand.

No EC2 instances to manage, which is nice.

### ECR (Elastic Container Registry)

Private Docker registry. When you build a container image, it gets pushed here. ECS pulls from here when starting containers.

We have image scanning enabled, so it automatically checks for known vulnerabilities. There's also a lifecycle policy that deletes old images to save on storage costs.

### Application Load Balancer

Sits in the public subnets and receives all incoming traffic. It distributes requests across healthy containers and does health checks. If a container goes down, it stops sending traffic there.

The ALB also gives us a single DNS name instead of managing individual container IPs.

### CloudWatch

Where all the logs and metrics go. Container logs end up in CloudWatch Logs, and we have Container Insights enabled for better visibility into what's happening.

We also set up alarms for things like container errors or high CPU usage. Useful for catching issues before they become problems.

### VPC Endpoints

This was important for our setup. Containers run in private subnets without internet access, but they still need to pull images from ECR and send logs to CloudWatch.

VPC endpoints create private connections from the VPC to AWS services. So containers can access ECR, CloudWatch, and S3 without going through the internet. More secure and actually cheaper than using NAT gateways.

We have endpoints for:
- ECR API and DKR (for pulling images)
- CloudWatch Logs (for sending logs)
- S3 (gateway endpoint, in case we need it)

### IAM Roles

Two roles here:
- Task execution role: Lets ECS pull images from ECR and write logs to CloudWatch
- Task role: Permissions for the application code itself (if it needs to access other AWS services)

Both follow least privilege - only the permissions they actually need.

### Auto Scaling

Monitors CPU usage and automatically adjusts the number of containers. We have it set to keep 2-4 containers running, scaling up when CPU gets high and down when it's low.

This helps with both performance and cost - you're not paying for idle containers.

### Security Groups

Virtual firewalls. The ALB security group allows HTTP traffic from anywhere. The ECS tasks security group only allows traffic from the ALB. Everything else is blocked by default.

## AWS Well-Architected Framework

### Operational Excellence

Everything is in Terraform, so infrastructure changes are version controlled and repeatable. The CI/CD pipeline (GitHub Actions) automatically builds and deploys when code is pushed.

CloudWatch Container Insights gives us real-time metrics, and we have alarms set up for common issues. All logs are centralized in CloudWatch Logs.

The GitHub Actions workflow uses OIDC to assume an IAM role, so no long-lived credentials stored in GitHub.

### Security

Containers run in private subnets with no public IPs. They can't be reached directly from the internet - all traffic goes through the load balancer.

Security groups restrict network access. VPC endpoints let containers access AWS services without internet access, which is more secure and avoids NAT gateway costs.

IAM roles follow least privilege. ECR images are scanned for vulnerabilities. Logs are encrypted at rest.

We had an issue initially where containers couldn't send logs to CloudWatch because they were in private subnets without internet. Adding the CloudWatch Logs VPC endpoint fixed that.

### Reliability

Resources are spread across multiple availability zones. The load balancer distributes traffic and handles failures automatically. If a container dies, ECS replaces it.

Auto scaling maintains the desired number of containers. Health checks ensure unhealthy containers are replaced.

Since everything is in Terraform, we can recreate the entire infrastructure if needed. Container images are versioned in ECR.

### Performance Efficiency

Fargate means no server management overhead. Containers are sized appropriately (256 CPU units, 512 MB memory in our case, but adjust based on your needs).

Auto scaling based on CPU utilization. VPC endpoints provide direct, private connections to AWS services with lower latency than going through the internet.

Container Insights helps identify bottlenecks and optimize resource usage.

### Cost Optimization

With Fargate, you only pay for running containers. No idle EC2 instances. Auto scaling means you scale down during low traffic periods.

VPC endpoints actually save money compared to NAT gateways for this use case. ECR lifecycle policies automatically clean up old images.

We're using cost allocation tags so we can track spending by project and environment.

## How It Works

### Deployment

1. Push code to GitHub
2. GitHub Actions builds a Docker image
3. Image gets pushed to ECR
4. Task definition is updated with the new image
5. ECS service does a rolling deployment
6. New containers start, health checks pass, traffic shifts over
7. Old containers are stopped

The rolling deployment means zero downtime - new containers come up before old ones are stopped.

### Request Flow

1. User makes a request
2. Hits the Application Load Balancer (in public subnet)
3. ALB checks security group rules (allows HTTP)
4. ALB routes to a healthy container (in private subnet)
5. Container processes the request
6. Container sends logs to CloudWatch via VPC endpoint
7. Response goes back through ALB to the user

### Container Startup

1. ECS service starts a new task in a private subnet
2. Task pulls the image from ECR via VPC endpoint
3. Container starts running
4. Logs start flowing to CloudWatch via VPC endpoint
5. Health check passes
6. ALB starts routing traffic to it
7. Auto scaling monitors and adjusts if needed

## Getting Started

### Prerequisites

- AWS account with permissions to create the resources
- Terraform installed (1.0 or later)
- AWS CLI configured
- GitHub repository with Actions enabled (for CI/CD)

### Setup

1. Clone the repo:
   ```bash
   git clone <repo-url>
   cd job
   ```

2. Set your variables in `terraform.tfvars`:
   ```
   project_name = "your-project"
   environment = "production"
   vpc_cidr = "10.0.0.0/16"
   ```

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan  # Review what will be created
   terraform apply
   ```

4. Set up GitHub secret:
   - Add `AWS_ROLE_ARN` to your GitHub repository secrets
   - This should be an IAM role that GitHub Actions can assume via OIDC

5. Push code to trigger the deployment pipeline

### Accessing the App

After deployment, get the load balancer DNS name:
```bash
terraform output alb_dns_name
```

Visit that URL in your browser.

## Monitoring

CloudWatch Container Insights is enabled, so you get detailed metrics about your containers. Check the ECS console or CloudWatch dashboards.

Key things to watch:
- CPU utilization (we scale at 80%)
- Memory usage
- Request count and error rate
- Number of running tasks (verify auto scaling is working)

We have alarms set up for container errors and high CPU. You can add more based on what you need.

## Maintenance

Regular stuff:
- Check CloudWatch logs for errors
- Review AWS billing to see actual costs
- Keep base images updated
- Check ECR scan results for vulnerabilities
- Test that you can recreate infrastructure from Terraform

For updates:
- Infrastructure changes: edit Terraform files and apply
- Application updates: just push code, CI/CD handles it
- Config changes: update variables and redeploy

## Common Issues

**Containers can't pull images or send logs**: Make sure VPC endpoints are created and security groups allow traffic to them. We had this issue initially - containers in private subnets need the endpoints to access AWS services.

**High costs**: Check if auto scaling is working. You might have more containers running than needed. Also verify ECR lifecycle policies are cleaning up old images.

**Deployment failures**: Check the GitHub Actions logs. Common issues are IAM permissions or the task definition not being found (the workflow handles this now).

## Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
