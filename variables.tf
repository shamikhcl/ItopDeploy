variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "demo"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

# These are mainly for wiring kubernetes/helm providers post-eks-create.
variable "kube_host" {
  description = "EKS API server endpoint"
  type        = string
  default     = ""
}

variable "kube_ca" {
  description = "Base64 cluster CA data"
  type        = string
  default     = ""
}

variable "kube_token" {
  description = "Auth token for Kubernetes provider"
  type        = string
  default     = ""
}

# Common tags
variable "tags" {
  description = "Map of common tags to apply to all resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
    env        = "dev"
  }
}
