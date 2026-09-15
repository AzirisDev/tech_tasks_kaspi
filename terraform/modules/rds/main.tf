# RDS PostgreSQL 14, Multi-AZ, gp3, 7-day backups (Task 6.4).
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project}-db-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]

  # Not publicly reachable; only the app SG can talk to it.
  publicly_accessible = false

  # Demo-friendly settings; tighten for real production.
  skip_final_snapshot = true
  apply_immediately   = true

  tags = merge(var.tags, { Name = "${var.project}-postgres" })
}
