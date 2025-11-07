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
