output "vpc_id" {
  description = "VPC ID from network module"
  value       = module.network.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = module.rds_mysql.db_endpoint
}
