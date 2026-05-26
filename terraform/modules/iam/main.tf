# ── Trust policies ────────────────────────────────────────────────────────────
# Each trust policy is locked to a single AWS service principal.
# No cross-account, no wildcard — only the service that needs the role can assume it.

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    sid     = "EKSControlPlaneAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }
  }
}

# ── Cluster role ──────────────────────────────────────────────────────────────
# Attached policy  : AmazonEKSClusterPolicy
# Grants           : EC2/ELB/CloudWatch/VPC permissions for the control plane.
# Nothing else     : no S3, no SecretsManager, no IAM write access.

resource "aws_iam_role" "cluster" {
  name        = "${var.cluster_name}-cluster-role"
  description = "Least-privilege role for the ${var.cluster_name} EKS control plane"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster-role" })
}

resource "aws_iam_role_policy_attachment" "cluster_eks_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── Node role ─────────────────────────────────────────────────────────────────
# Attached policies (minimum required for managed node groups):
#
#   AmazonEKSWorkerNodePolicy          — register node with cluster, describe cluster
#   AmazonEKS_CNI_Policy               — VPC CNI plugin: assign/release pod IPs
#   AmazonEC2ContainerRegistryReadOnly — pull images; read-only, no push/delete
#
# NOT attached: AdministratorAccess, AmazonEC2FullAccess, S3 full access, etc.
# Application-level AWS access (S3, DynamoDB, …) must use IRSA per service account,
# never the node role.

resource "aws_iam_role" "node" {
  name        = "${var.cluster_name}-node-role"
  description = "Least-privilege role for ${var.cluster_name} managed node group"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = merge(var.tags, { Name = "${var.cluster_name}-node-role" })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
