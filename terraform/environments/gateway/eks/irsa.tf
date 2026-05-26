locals {
  gateway_oidc_host = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

data "aws_iam_policy_document" "gateway_irsa_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.gateway_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.gateway_oidc_host}:sub"
      values   = ["system:serviceaccount:sentinel-gateway:gateway"]
    }
  }
}

resource "aws_iam_role" "gateway_irsa" {
  name               = "${local.cluster_name}-irsa-gateway"
  assume_role_policy = data.aws_iam_policy_document.gateway_irsa_assume.json

  tags = { Name = "${local.cluster_name}-irsa-gateway" }
}

data "aws_iam_policy_document" "gateway_secrets_read" {
  statement {
    sid     = "SecretsManagerRead"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:sentinel/*"
    ]
  }
}

resource "aws_iam_policy" "gateway_secrets_read" {
  name   = "${local.cluster_name}-gateway-secrets-read"
  policy = data.aws_iam_policy_document.gateway_secrets_read.json
}

resource "aws_iam_role_policy_attachment" "gateway_irsa_secrets" {
  role       = aws_iam_role.gateway_irsa.name
  policy_arn = aws_iam_policy.gateway_secrets_read.arn
}