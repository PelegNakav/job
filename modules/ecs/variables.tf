variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of public subnets for ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Container image to run (can be public Docker Hub or ECR image)"
  type        = string
  default     = "nginxdemos/hello:latest"
}

variable "desired_count" {
  description = "Desired number of containers"
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Minimum number of containers"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum number of containers"
  type        = number
  default     = 4
}

variable "container_memory" {
  description = "Container memory in MiB"
  type        = number
  default     = 512
}

variable "container_cpu" {
  description = "Container CPU units"
  type        = number
  default     = 256
}

variable "health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/"
}