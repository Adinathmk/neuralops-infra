output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateway(s)"
  value       = aws_nat_gateway.main[*].id
}

output "eks_cluster_id" {
  value = aws_eks_cluster.main.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca_certificate" {
  value     = aws_eks_cluster.main.certificate_authority[0].data
  sensitive = true
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}
output "eks_node_group_arn" {
  value = aws_eks_node_group.main.arn
}

output "eks_node_group_asg_name" {
  value = aws_eks_node_group.main.resources[0].autoscaling_groups[0].name
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node.arn
}
output "django_db_endpoint" {
  value = aws_db_instance.django.endpoint
}

output "django_db_name" {
  value = aws_db_instance.django.db_name
}

output "fastapi_db_endpoint" {
  value = aws_db_instance.fastapi.endpoint
}

output "fastapi_db_name" {
  value = aws_db_instance.fastapi.db_name
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}
output "redis_endpoint" {
  value = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  value = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}
output "artifacts_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  value = aws_s3_bucket.artifacts.arn
}
