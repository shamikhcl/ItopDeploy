# VPC, subnets, routing go here.
# (intentionally left minimal; implement as needed)

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# You will typically create:
# - public subnets (for ingress / NAT)
# - private subnets (for EKS nodes and RDS)
# - route tables
# - igw / nat gateway (optional)
#
# Expose subnet IDs via outputs.
