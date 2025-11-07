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
