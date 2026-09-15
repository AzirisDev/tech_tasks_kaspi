variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "devops-test"
}

variable "vpc_id" {
  description = "VPC ID the security groups belong to."
  type        = string
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
