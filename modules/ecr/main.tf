# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = var.image_tag_mutability
  force_delete        = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name        = "${var.project_name}-repo"
    Environment = var.environment
  }
}

# Repository Policy
resource "aws_ecr_repository_policy" "app_policy" {
  repository = aws_ecr_repository.app.name
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullFromECS"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "app_lifecycle" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}