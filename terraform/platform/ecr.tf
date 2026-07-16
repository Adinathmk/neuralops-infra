# ============================================================
# ECR — image repositories, one per deployable image.
# ============================================================

locals {
  ecr_repos = [
    "neuralops-django",
    "neuralops-django-worker",
    "neuralops-django-kafka-consumer",
    "neuralops-fastapi",
  ]
}

resource "aws_ecr_repository" "main" {
  for_each = toset(local.ecr_repos)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = aws_ecr_repository.main

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
