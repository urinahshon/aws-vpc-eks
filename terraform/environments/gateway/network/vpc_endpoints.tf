resource "aws_security_group" "vpc_endpoints" {
  name        = "gateway-vpc-endpoints"
  description = "Allow HTTPS from gateway VPC to SSM interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from gateway VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "gateway-vpc-endpoints" }
}

locals {
  ssm_endpoints = toset(["ssm", "ssmmessages", "ec2messages"])
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = local.ssm_endpoints

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "gateway-${each.key}" }
}