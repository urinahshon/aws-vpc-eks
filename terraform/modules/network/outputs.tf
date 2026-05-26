output "nat_gateway_ids" {
  description = "NAT Gateway IDs, one per AZ"
  value       = aws_nat_gateway.this[*].id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs, one per AZ — used by root module to add peering routes"
  value       = aws_route_table.private[*].id
}