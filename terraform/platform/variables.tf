variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (used in tags and resource naming)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "neuralops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway (cheaper, less HA) instead of one per AZ."
  type        = bool
  default     = true
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.30"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.small"
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 3
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes (for autoscaling)"
  type        = number
  default     = 4
}

variable "rds_instance_class" {
  description = "RDS instance class for both Postgres databases"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage (GB) for each RDS instance"
  type        = number
  default     = 30
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS. Off by default for cost."
  type        = bool
  default     = false
}

variable "elasticache_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}
