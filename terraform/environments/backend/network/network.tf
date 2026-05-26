module "networking" {
  source = "../../../modules/network"

  name                = "backend"
  vpc_id              = module.vpc.vpc_id
  azs                 = var.azs
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  internet_gateway_id = module.vpc.internet_gateway_id
}