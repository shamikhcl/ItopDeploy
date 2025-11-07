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
