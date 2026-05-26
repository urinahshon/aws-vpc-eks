output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_route_table_ids" {
  description = "Consumed by peering environment to add the gateway → backend route"
  value       = module.networking.private_route_table_ids
}

output "cluster_sg_id" {
  value = module.security_groups.cluster_sg_id
}

output "node_sg_id" {
  value = module.security_groups.node_sg_id
}