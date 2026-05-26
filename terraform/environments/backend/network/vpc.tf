module "vpc" {
  source = "../../../modules/vpc"

  name                  = "backend"
  vpc_cidr              = var.vpc_cidr
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  cluster_name          = local.cluster_name
  # Public subnets exist only to host NAT Gateways — no internet-facing LBs allowed.
  enable_public_elb_tag = false
}