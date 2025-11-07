variable "project_name" {
  type        = string
  description = "Name prefix"
}

variable "aws_region" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "Set true if you want private subnets with outbound internet via NAT"
}
