module "iam" {
  source         = "../../modules/iam"
  cluster_name   = local.cluster_name
  aws_account_id = var.aws_account_id
}
