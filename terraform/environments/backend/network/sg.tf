module "security_groups" {
  source       = "../../../modules/security-groups"
  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id

  additional_node_sg_ingress = [
    {
      description = "HTTP from gateway private subnets via internal NLB (port 80 only)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.gateway_private_subnet_cidrs
    },
    {
      description = "NLB health-check probes from backend private subnets (port 80 only)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.private_subnet_cidrs
    },
  ]
}