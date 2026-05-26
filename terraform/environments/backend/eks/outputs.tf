# These outputs are consumed by the gateway environment via terraform_remote_state.
# Any value the gateway needs to set up peering or routing must be exported here.

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "private_route_table_ids" {
  description = "Used by gateway environment to add the return peering route"
  value       = module.networking.private_route_table_ids
}

output "node_sg_id" {
  value = module.security_groups.node_sg_id
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
