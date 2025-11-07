# aws-infra
Terraform IaC for:
- VPC / subnets / routing (modules/network)
- EKS cluster and node groups (modules/eks)
- RDS MySQL instance (modules/rds-mysql)

Use `envs/dev/terraform.tfvars` etc. to size resources (small in dev, bigger in prod).
