output "cluster_name" {
  value = aws_eks_cluster.this.name
}

# Add more if you expose endpoint, CA, OIDC, etc.
