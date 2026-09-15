# Key outputs (Task 6.5).
output "eks_cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name (for kubeconfig)."
  value       = module.eks.cluster_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.rds.rds_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL for docker push."
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}
