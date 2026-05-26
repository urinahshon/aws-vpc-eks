data "terraform_remote_state" "gateway" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = var.gateway_state_key
    region = var.aws_region
  }
}

data "terraform_remote_state" "backend" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = var.backend_state_key
    region = var.aws_region
  }
}

resource "aws_vpc_peering_connection" "this" {
  vpc_id      = data.terraform_remote_state.gateway.outputs.vpc_id
  peer_vpc_id = data.terraform_remote_state.backend.outputs.vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = { Name = "pcx-gateway-to-backend" }
}

# gateway private subnets → backend VPC
resource "aws_route" "gateway_to_backend" {
  count = length(data.terraform_remote_state.gateway.outputs.private_route_table_ids)

  route_table_id            = data.terraform_remote_state.gateway.outputs.private_route_table_ids[count.index]
  destination_cidr_block    = data.terraform_remote_state.backend.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# backend private subnets → gateway VPC (return path)
resource "aws_route" "backend_to_gateway" {
  count = length(data.terraform_remote_state.backend.outputs.private_route_table_ids)

  route_table_id            = data.terraform_remote_state.backend.outputs.private_route_table_ids[count.index]
  destination_cidr_block    = data.terraform_remote_state.gateway.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}