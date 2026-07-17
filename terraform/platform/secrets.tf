# ============================================================
# Secrets Manager — Django & FastAPI application secrets.
# Category A (derived from real infra) + Category B (freshly
# generated for prod). Category C/D keys added in a later pass.
# ============================================================

resource "random_password" "django_secret_key" {
  length           = 64
  special          = true
  override_special = "!@#$%^&*(-_=+)"
}

resource "tls_private_key" "jwt" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

variable "fernet_encryption_key" {
  description = "Django Fernet key — generate via: python3 -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
  type        = string
  sensitive   = true
}

variable "vapid_private_key" {
  description = "VAPID private key for web push — generate via: npx web-push generate-vapid-keys"
  type        = string
  sensitive   = true
}

locals {
  django_db_url = "postgresql://${aws_db_instance.django.username}:${random_password.django_db.result}@${aws_db_instance.django.address}:${aws_db_instance.django.port}/${aws_db_instance.django.db_name}"

  fastapi_db_url = "postgresql://${aws_db_instance.fastapi.username}:${random_password.fastapi_db.result}@${aws_db_instance.fastapi.address}:${aws_db_instance.fastapi.port}/${aws_db_instance.fastapi.db_name}"

  redis_host = aws_elasticache_cluster.main.cache_nodes[0].address
  redis_port = aws_elasticache_cluster.main.cache_nodes[0].port

  redis_url = "redis://${local.redis_host}:${local.redis_port}"
}

resource "aws_secretsmanager_secret" "django" {
  name = "${var.project_name}/django"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({
    DATABASE_URL          = local.django_db_url
    DATABASE_REPLICA_URL  = local.django_db_url # TODO: point at a real read replica once one exists
    REDIS_URL             = "${local.redis_url}/0"
    SECRET_KEY            = random_password.django_secret_key.result
    FERNET_ENCRYPTION_KEY = var.fernet_encryption_key
    JWT_PRIVATE_KEY       = tls_private_key.jwt.private_key_pem
    JWT_PUBLIC_KEY        = tls_private_key.jwt.public_key_pem
    VAPID_PRIVATE_KEY     = var.vapid_private_key
  })
}

resource "aws_secretsmanager_secret" "fastapi" {
  name = "${var.project_name}/fastapi"
}

resource "aws_secretsmanager_secret_version" "fastapi" {
  secret_id = aws_secretsmanager_secret.fastapi.id
  secret_string = jsonencode({
    DATABASE_URL          = local.fastapi_db_url
    REDIS_URL             = "${local.redis_url}/1"
    CELERY_BROKER_URL     = "${local.redis_url}/2" # TODO: confirm db number matches app expectations
    CELERY_RESULT_BACKEND = "${local.redis_url}/2" # TODO: confirm — same db as broker, or different?
    JWT_PUBLIC_KEY        = tls_private_key.jwt.public_key_pem
  })
}
