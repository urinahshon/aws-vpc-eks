module "eks" {
  source = "../../../modules/eks"

  cluster_name        = local.cluster_name
  kubernetes_version  = var.kubernetes_version
  subnet_ids          = data.terraform_remote_state.network.outputs.private_subnet_ids
  cluster_sg_id       = data.terraform_remote_state.network.outputs.cluster_sg_id
  node_sg_id          = data.terraform_remote_state.network.outputs.node_sg_id
  cluster_role_arn    = module.iam.cluster_role_arn
  node_role_arn       = module.iam.node_role_arn
  node_instance_types = var.node_instance_types
}