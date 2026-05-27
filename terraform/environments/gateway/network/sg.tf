module "security_groups" {
  source       = "../../../modules/security-groups"
  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id

  additional_node_sg_ingress = [
    {
      description = "Internet to gateway pods via public NLB (port 80 only)"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "NLB health-check probes from gateway private subnets"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.private_subnet_cidrs
    },
  ]
}