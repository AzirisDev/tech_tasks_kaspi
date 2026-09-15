variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
  default     = "flask-app"
}

variable "image_tag_mutability" {
  description = "IMMUTABLE or MUTABLE tag policy."
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable image vulnerability scanning on push."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the repository."
  type        = map(string)
  default     = {}
}
