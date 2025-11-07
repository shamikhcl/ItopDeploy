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
