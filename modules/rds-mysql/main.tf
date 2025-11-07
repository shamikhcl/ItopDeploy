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
