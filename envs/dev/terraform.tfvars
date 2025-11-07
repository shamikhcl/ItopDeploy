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
