data "terraform_remote_state" "gateway_eks" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/gateway/eks/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_eks_access_entry" "bastion" {
  cluster_name  = data.terraform_remote_state.gateway_eks.outputs.cluster_name
  principal_arn = aws_iam_role.bastion.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name  = data.terraform_remote_state.gateway_eks.outputs.cluster_name
  principal_arn = aws_iam_role.bastion.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion]
}