#!/bin/bash

set -euo pipefail

PROJECT_ROOT="."

echo "Creating Terraform project scaffold: $PROJECT_ROOT"

# --- directories ---
dirs=(
  "$PROJECT_ROOT"
  "$PROJECT_ROOT/envs"
  "$PROJECT_ROOT/envs/dev"
  "$PROJECT_ROOT/envs/prod"
  "$PROJECT_ROOT/modules"
  "$PROJECT_ROOT/modules/network"
  "$PROJECT_ROOT/modules/eks"
  "$PROJECT_ROOT/modules/rds-mysql"
  "$PROJECT_ROOT/scripts"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

# --- top-level files ---
cat > "$PROJECT_ROOT/README.md" << 'EOF'
# aws-infra
Terraform IaC for:
- VPC / subnets / routing (modules/network)
- EKS cluster and node groups (modules/eks)
- RDS MySQL instance (modules/rds-mysql)

Use `envs/dev/terraform.tfvars` etc. to size resources (small in dev, bigger in prod).
EOF

cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# Terraform state
*.tfstate
*.tfstate.*
.terraform/
.terraform.*

# crash logs
crash.log
crash.*.log

# auto tfvars secrets
*.auto.tfvars
*.tfvars.json

# local kubeconfig outputs etc.
kubeconfig_*
EOF

cat > "$PROJECT_ROOT/versions.tf" << 'EOF'
terraform {
  required_version = ">= 1.8.0"

  # backend config for remote state (S3 + DynamoDB) can go in backend.tf
  # or you can inline here if you prefer.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}
EOF

cat > "$PROJECT_ROOT/providers.tf" << 'EOF'
provider "aws" {
  region = var.aws_region
}

# You'll typically configure these after cluster is created,
# e.g. using data from module.eks outputs.
provider "kubernetes" {
  host                   = var.kube_host
  cluster_ca_certificate = base64decode(var.kube_ca)
  token                  = var.kube_token
}

provider "helm" {
  kubernetes {
    host                   = var.kube_host
    cluster_ca_certificate = base64decode(var.kube_ca)
    token                  = var.kube_token
  }
}
EOF

cat > "$PROJECT_ROOT/backend.tf" << 'EOF'
# Remote state backend (optional).
# Uncomment + fill if you want to use S3 & DynamoDB for locking.
#
# terraform {
#   backend "s3" {
#     bucket         = "my-tf-state-bucket"
#     key            = "aws-infra/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "tf-locks"
#     encrypt        = true
#   }
# }
EOF

cat > "$PROJECT_ROOT/variables.tf" << 'EOF'
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "demo"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

# These are mainly for wiring kubernetes/helm providers post-eks-create.
variable "kube_host" {
  description = "EKS API server endpoint"
  type        = string
  default     = ""
}

variable "kube_ca" {
  description = "Base64 cluster CA data"
  type        = string
  default     = ""
}

variable "kube_token" {
  description = "Auth token for Kubernetes provider"
  type        = string
  default     = ""
}

# Common tags
variable "tags" {
  description = "Map of common tags to apply to all resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
    env        = "dev"
  }
}
EOF

cat > "$PROJECT_ROOT/outputs.tf" << 'EOF'
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
EOF

cat > "$PROJECT_ROOT/main.tf" << 'EOF'
#####################################
# Root module wiring
#####################################

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  aws_region   = var.aws_region
  tags         = var.tags
}

module "eks" {
  source = "./modules/eks"

  project_name   = var.project_name
  aws_region     = var.aws_region
  vpc_id         = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  node_instance_type = var.eks_node_instance_type
  node_desired_size  = var.eks_node_desired_size
  node_min_size      = var.eks_node_min_size
  node_max_size      = var.eks_node_max_size

  tags = var.tags
}

module "rds_mysql" {
  source = "./modules/rds-mysql"

  project_name        = var.project_name
  aws_region          = var.aws_region
  vpc_id              = module.network.vpc_id
  db_subnet_ids       = module.network.private_subnet_ids
  allowed_cidr_blocks = var.db_allowed_cidr_blocks

  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  db_instance_class   = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  backup_retention    = var.db_backup_retention

  tags                = var.tags
}

#####################################
# Extra variables referenced above,
# defined here so terraform doesn't complain.
#####################################

variable "eks_node_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Instance type for managed node group"
}

variable "eks_node_desired_size" {
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  type        = number
  default     = 3
}

variable "db_allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "CIDR ranges that can reach MySQL"
}

variable "db_name" {
  type        = string
  default     = "appdb"
}

variable "db_username" {
  type        = string
  default     = "appuser"
}

variable "db_password" {
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type        = number
  default     = 20
}

variable "db_backup_retention" {
  type        = number
  default     = 1
  description = "Days to keep automated backups (dev can be 1)"
}
EOF

######################################
# envs/dev
######################################
cat > "$PROJECT_ROOT/envs/dev/terraform.tfvars" << 'EOF'
project_name            = "demo-dev"
aws_region              = "ap-south-1"

eks_node_instance_type  = "t3.small"
eks_node_desired_size   = 2
eks_node_min_size       = 1
eks_node_max_size       = 2

db_name                 = "appdb"
db_username             = "appuser"
db_password             = "DevOnlyPassword123!"
db_instance_class       = "db.t4g.micro"
db_allocated_storage    = 20
db_backup_retention     = 1

db_allowed_cidr_blocks  = ["10.0.0.0/16"]

tags = {
  managed-by = "terraform"
  env        = "dev"
}
EOF

cat > "$PROJECT_ROOT/envs/dev/override.auto.tfvars" << 'EOF'
# optional local overrides for dev only
EOF

######################################
# envs/prod
######################################
cat > "$PROJECT_ROOT/envs/prod/terraform.tfvars" << 'EOF'
project_name            = "demo-prod"
aws_region              = "ap-south-1"

eks_node_instance_type  = "t3.medium"
eks_node_desired_size   = 3
eks_node_min_size       = 2
eks_node_max_size       = 4

db_name                 = "appdb"
db_username             = "appuser"
db_password             = "ProdPasswordChangeMe!"
db_instance_class       = "db.t4g.small"
db_allocated_storage    = 50
db_backup_retention     = 7

db_allowed_cidr_blocks  = ["10.0.0.0/16"]

tags = {
  managed-by = "terraform"
  env        = "prod"
}
EOF

######################################
# modules/network
######################################
cat > "$PROJECT_ROOT/modules/network/README.md" << 'EOF'
This module creates:
- VPC
- public/private subnets
- route tables, IGW, NAT (optional)
Outputs are consumed by EKS and RDS modules.
EOF

cat > "$PROJECT_ROOT/modules/network/variables.tf" << 'EOF'
variable "project_name" {
  type        = string
  description = "Name prefix"
}

variable "aws_region" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "Set true if you want private subnets with outbound internet via NAT"
}
EOF

cat > "$PROJECT_ROOT/modules/network/main.tf" << 'EOF'
# VPC, subnets, routing go here.
# (intentionally left minimal; implement as needed)

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# You will typically create:
# - public subnets (for ingress / NAT)
# - private subnets (for EKS nodes and RDS)
# - route tables
# - igw / nat gateway (optional)
#
# Expose subnet IDs via outputs.
EOF

cat > "$PROJECT_ROOT/modules/network/outputs.tf" << 'EOF'
output "vpc_id" {
  value = aws_vpc.this.id
}

# placeholder lists - update with real subnet resources when you add them
output "private_subnet_ids" {
  value = []
}

output "public_subnet_ids" {
  value = []
}
EOF

######################################
# modules/eks
######################################
cat > "$PROJECT_ROOT/modules/eks/README.md" << 'EOF'
This module creates:
- EKS cluster
- managed node group
- IAM roles (incl. OIDC / IRSA if you add it)
EOF

cat > "$PROJECT_ROOT/modules/eks/locals.tf" << 'EOF'
locals {
  cluster_name = "${var.project_name}-eks"
}
EOF

cat > "$PROJECT_ROOT/modules/eks/variables.tf" << 'EOF'
variable "project_name" {
  type        = string
  description = "Name prefix used for cluster and nodegroups"
}

variable "aws_region" {
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "VPC to run EKS in"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets where worker nodes will run"
}

variable "node_instance_type" {
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  type        = number
  default     = 2
}

variable "node_min_size" {
  type        = number
  default     = 1
}

variable "node_max_size" {
  type        = number
  default     = 3
}

variable "tags" {
  type        = map(string)
  default     = {}
}
EOF

cat > "$PROJECT_ROOT/modules/eks/security.tf" << 'EOF'
# Security groups, cluster SG, nodegroup SG, etc.
# Define aws_security_group for cluster / nodes here later.
EOF

cat > "$PROJECT_ROOT/modules/eks/iam.tf" << 'EOF'
# IAM roles, policies, and IRSA can live here.
EOF

cat > "$PROJECT_ROOT/modules/eks/data.tf" << 'EOF'
# data sources like aws_caller_identity, aws_eks_cluster_auth etc.
EOF

cat > "$PROJECT_ROOT/modules/eks/main.tf" << 'EOF'
# Minimal skeleton. You'll fill in aws_eks_cluster and aws_eks_node_group.

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = "REPLACE_ME_CLUSTER_ROLE_ARN"

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  # You will add version, endpoint_public_access, etc.
  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-ng"
  node_role_arn   = "REPLACE_ME_NODEGROUP_ROLE_ARN"

  subnet_ids      = var.private_subnet_ids
  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = [var.node_instance_type]

  tags = var.tags
}
EOF

cat > "$PROJECT_ROOT/modules/eks/outputs.tf" << 'EOF'
output "cluster_name" {
  value = aws_eks_cluster.this.name
}

# Add more if you expose endpoint, CA, OIDC, etc.
EOF

######################################
# modules/rds-mysql
######################################
cat > "$PROJECT_ROOT/modules/rds-mysql/README.md" << 'EOF'
This module creates:
- DB subnet group
- Security group for MySQL
- MySQL RDS instance (single AZ by default for dev)
EOF

cat > "$PROJECT_ROOT/modules/rds-mysql/variables.tf" << 'EOF'
variable "project_name" {
  type        = string
  description = "Used as prefix for DB instance identifiers, etc."
}

variable "aws_region" {
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "VPC where RDS lives"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Private subnets for DB subnet group"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR ranges allowed to connect to MySQL"
  default     = []
}

variable "db_name" {
  type        = string
  default     = "appdb"
}

variable "db_username" {
  type        = string
  default     = "appuser"
}

variable "db_password" {
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  default     = 20
}

variable "backup_retention" {
  type        = number
  default     = 1
  description = "Days to keep automated snapshots"
}

variable "tags" {
  type        = map(string)
  default     = {}
}
EOF

cat > "$PROJECT_ROOT/modules/rds-mysql/security.tf" << 'EOF'
# Security group allowing restricted inbound MySQL (3306)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "MySQL access SG"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      description = "MySQL access"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
EOF

cat > "$PROJECT_ROOT/modules/rds-mysql/subnet-group.tf" << 'EOF'
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = var.tags
}
EOF

cat > "$PROJECT_ROOT/modules/rds-mysql/parameter-group.tf" << 'EOF'
resource "aws_db_parameter_group" "this" {
  name        = "${var.project_name}-mysql-params"
  family      = "mysql8.0"
  description = "Custom params for MySQL"

  # Example tweak (commented out):
  # parameter {
  #   name  = "slow_query_log"
  #   value = "1"
  # }

  tags = var.tags
}
EOF

cat > "$PROJECT_ROOT/modules/rds-mysql/main.tf" << 'EOF'
resource "aws_db_instance" "this" {
  identifier                = "${var.project_name}-mysql"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = var.db_instance_class
  username                  = var.db_username
  password                  = var.db_password
  db_name                   = var.db_name
  allocated_storage         = var.allocated_storage
  max_allocated_storage     = var.allocated_storage + 20
  backup_retention_period   = var.backup_retention
  skip_final_snapshot       = true
  db_subnet_group_name      = aws_db_subnet_group.this.name
  parameter_group_name      = aws_db_parameter_group.this.name
  vpc_security_group_ids    = [aws_security_group.db_sg.id]
  publicly_accessible       = false
  multi_az                  = false
  storage_encrypted         = true
  deletion_protection       = false

  tags = var.tags
}
EOF

cat > "$PROJECT_ROOT/modules/rds-mysql/outputs.tf" << 'EOF'
output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "security_group_id" {
  value = aws_security_group.db_sg.id
}
EOF

######################################
# scripts
######################################
cat > "$PROJECT_ROOT/scripts/kubeconfig_eks.sh" << 'EOF'
#!/bin/bash
# Usage: ./kubeconfig_eks.sh <cluster-name> <region>
set -euo pipefail
CLUSTER_NAME="${1:-demo-dev-eks}"
REGION="${2:-ap-south-1}"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"
EOF
chmod +x "$PROJECT_ROOT/scripts/kubeconfig_eks.sh"

cat > "$PROJECT_ROOT/scripts/print_db_secrets.sh" << 'EOF'
#!/bin/bash
# This is a placeholder helper to pull DB info from terraform output.
set -euo pipefail
terraform output -json | jq '.rds_endpoint'
EOF
chmod +x "$PROJECT_ROOT/scripts/print_db_secrets.sh"

echo "Scaffold complete."
