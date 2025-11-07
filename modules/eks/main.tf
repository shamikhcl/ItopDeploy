# Minimal skeleton. You'll fill in aws_eks_cluster and aws_eks_node_group.

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = "REPLACE_ME_CLUSTER_ROLE_ARN"

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  # You will add version, endpoint_public_access, etc.
  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-ng"
  node_role_arn   = "REPLACE_ME_NODEGROUP_ROLE_ARN"

  subnet_ids      = var.private_subnet_ids
  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = [var.node_instance_type]

  tags = var.tags
}
