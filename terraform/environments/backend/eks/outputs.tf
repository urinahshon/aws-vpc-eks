output "node_sg_id" {
  value = data.terraform_remote_state.network.outputs.node_sg_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "irsa_backend_role_arn" {
  description = "IRSA role ARN for backend pods — annotate the backend ServiceAccount with this"
  value       = aws_iam_role.backend_irsa.arn
}
