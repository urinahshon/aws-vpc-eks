module "vpc" {
  source = "../../../modules/vpc"

  name                 = "gateway"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
  enable_public_elb_tag = true
}