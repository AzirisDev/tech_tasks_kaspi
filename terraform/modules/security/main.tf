# Security groups for the app and the database (Task 6.2).

# ---- App SG: allow 80/443 from the internet, all egress ----
resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "App: allow HTTP/HTTPS in, all out"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project}-app-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_all_out" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---- DB SG: allow 5432 only from the app SG, minimal egress ----
resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "DB: allow 5432 from app SG only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project}-db-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from app SG"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# Minimal egress: allow return traffic within the VPC only.
resource "aws_vpc_security_group_egress_rule" "db_out" {
  security_group_id = aws_security_group.db.id
  description       = "Restricted outbound within VPC"
  cidr_ipv4         = "10.0.0.0/16"
  ip_protocol       = "-1"
}
