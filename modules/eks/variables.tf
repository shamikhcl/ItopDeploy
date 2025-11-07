variable "project_name" {
  type        = string
  description = "Name prefix used for cluster and nodegroups"
}

variable "aws_region" {
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "VPC to run EKS in"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets where worker nodes will run"
}

variable "node_instance_type" {
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  type        = number
  default     = 2
}

variable "node_min_size" {
  type        = number
  default     = 1
}

variable "node_max_size" {
  type        = number
  default     = 3
}

variable "tags" {
  type        = map(string)
  default     = {}
}
