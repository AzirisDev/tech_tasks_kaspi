variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "devops-test"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID to attach to the RDS instance."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "14"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB."
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "EBS storage type."
  type        = string
  default     = "gp3"
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Days to retain automated backups."
  type        = number
  default     = 7
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Master password. Pass via TF_VAR_db_password or a secret store, never hard-code."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
