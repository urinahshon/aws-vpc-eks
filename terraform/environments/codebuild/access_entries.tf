# Grant the CodeBuild service role cluster-admin access to both EKS clusters
# using the EKS Access Entries API (supported on EKS 1.23+).

resource "aws_eks_access_entry" "codebuild_backend" {
  cluster_name  = data.terraform_remote_state.backend_eks.outputs.cluster_name
  principal_arn = aws_iam_role.codebuild.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "codebuild_backend" {
  cluster_name  = data.terraform_remote_state.backend_eks.outputs.cluster_name
  principal_arn = aws_iam_role.codebuild.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.codebuild_backend]
}

resource "aws_eks_access_entry" "codebuild_gateway" {
  cluster_name  = data.terraform_remote_state.gateway_eks.outputs.cluster_name
  principal_arn = aws_iam_role.codebuild.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "codebuild_gateway" {
  cluster_name  = data.terraform_remote_state.gateway_eks.outputs.cluster_name
  principal_arn = aws_iam_role.codebuild.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.codebuild_gateway]
}