output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.this.id
}

output "gateway_vpc_id" {
  value = data.terraform_remote_state.gateway.outputs.vpc_id
}

output "backend_vpc_id" {
  value = data.terraform_remote_state.backend.outputs.vpc_id
}