variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix for all resources."
  type        = string
  default     = "devops-test"
}

variable "azs" {
  description = "Availability zones."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_password" {
  description = "RDS master password. Provide via TF_VAR_db_password or -var-file; never commit it."
  type        = string
  sensitive   = true
}
