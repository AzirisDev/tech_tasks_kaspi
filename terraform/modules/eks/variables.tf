variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "devops-test"
}

variable "cluster_version" {
  description = "EKS control plane version (>= 1.27)."
  type        = string
  default     = "1.30"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (control plane ENIs / public access)."
  type        = list(string)
}

variable "instance_type" {
  description = "Worker node instance type."
  type        = string
  default     = "t3.medium"
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
