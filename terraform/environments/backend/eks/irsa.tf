locals {
  backend_oidc_host = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

data "aws_iam_policy_document" "backend_irsa_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.backend_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.backend_oidc_host}:sub"
      values   = ["system:serviceaccount:sentinel-backend:backend"]
    }
  }
}

resource "aws_iam_role" "backend_irsa" {
  name               = "${local.cluster_name}-irsa-backend"
  assume_role_policy = data.aws_iam_policy_document.backend_irsa_assume.json

  tags = { Name = "${local.cluster_name}-irsa-backend" }
}

data "aws_iam_policy_document" "backend_secrets_read" {
  statement {
    sid     = "SecretsManagerRead"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:sentinel/*"
    ]
  }
}

resource "aws_iam_policy" "backend_secrets_read" {
  name   = "${local.cluster_name}-backend-secrets-read"
  policy = data.aws_iam_policy_document.backend_secrets_read.json
}

resource "aws_iam_role_policy_attachment" "backend_irsa_secrets" {
  role       = aws_iam_role.backend_irsa.name
  policy_arn = aws_iam_policy.backend_secrets_read.arn
}
