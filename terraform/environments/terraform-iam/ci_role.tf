# ── Trust policy ──────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "ci_assume_role" {
  statement {
    sid     = "GitHubActionsOIDC"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = local.role_name
  description        = "Assumed by GitHub Actions OIDC to provision VPC, EKS, and EKS IAM resources via Terraform"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json
}

# ── VPC & networking ──────────────────────────────────────────────────────────

data "aws_iam_policy_document" "vpc_networking" {
  statement {
    sid = "VPC"
    actions = [
      "ec2:CreateVpc", "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute", "ec2:DescribeVpcs", "ec2:DescribeVpcAttribute",
      "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute", "ec2:DescribeSubnets",
      "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway", "ec2:DescribeInternetGateways",
      "ec2:AllocateAddress", "ec2:ReleaseAddress",
      "ec2:DescribeAddresses", "ec2:DescribeAddressesAttribute",
      "ec2:CreateNatGateway", "ec2:DeleteNatGateway", "ec2:DescribeNatGateways",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateRoute", "ec2:DeleteRoute", "ec2:ReplaceRoute", "ec2:DescribeRouteTables",
      "ec2:CreateVpcPeeringConnection", "ec2:DeleteVpcPeeringConnection",
      "ec2:AcceptVpcPeeringConnection", "ec2:ModifyVpcPeeringConnectionOptions",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeTags",
      "ec2:DescribeAvailabilityZones", "ec2:DescribeAccountAttributes",
      "ec2:DescribeNetworkInterfaces",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "security_groups" {
  statement {
    sid = "SecurityGroups"
    actions = [
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules",
      "ec2:ModifySecurityGroupRules",
    ]
    resources = ["*"]
  }
}

# ── EKS ───────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "eks" {
  statement {
    sid = "EKS"
    actions = [
      "eks:CreateCluster", "eks:DeleteCluster",
      "eks:DescribeCluster", "eks:UpdateClusterConfig", "eks:UpdateClusterVersion",
      "eks:ListClusters", "eks:TagResource", "eks:UntagResource",
      "eks:CreateNodegroup", "eks:DeleteNodegroup",
      "eks:DescribeNodegroup", "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion", "eks:ListNodegroups",
      "eks:AssociateIdentityProviderConfig", "eks:DisassociateIdentityProviderConfig",
      "eks:DescribeIdentityProviderConfig", "eks:ListIdentityProviderConfigs",
    ]
    resources = ["*"]
  }
}

# ── IAM for EKS (scoped to permitted eks-* and sentinel-* prefixes) ──────────

data "aws_iam_policy_document" "iam_for_eks" {
  # Read-only operations that don't support resource-level restrictions
  statement {
    sid = "IAMRead"
    actions = [
      "iam:GetRole", "iam:ListRoles",
      "iam:GetPolicy", "iam:ListPolicies",
      "iam:GetPolicyVersion", "iam:ListPolicyVersions",
      "iam:GetRolePolicy", "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:GetOpenIDConnectProvider", "iam:ListOpenIDConnectProviders",
    ]
    resources = ["*"]
  }

  # Write operations scoped to permitted role prefixes (eks-* and sentinel-*)
  statement {
    sid = "IAMRolesForEKS"
    actions = [
      "iam:CreateRole", "iam:DeleteRole",
      "iam:UpdateRoleDescription", "iam:UpdateAssumeRolePolicy",
      "iam:TagRole", "iam:UntagRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:role/eks-*",
      "arn:aws:iam::${var.aws_account_id}:role/sentinel-*",
    ]
  }

  # Write operations scoped to permitted policy prefixes (eks-* and sentinel-*)
  statement {
    sid = "IAMPoliciesForEKS"
    actions = [
      "iam:CreatePolicy", "iam:DeletePolicy",
      "iam:TagPolicy", "iam:UntagPolicy",
      "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:policy/eks-*",
      "arn:aws:iam::${var.aws_account_id}:policy/sentinel-*",
    ]
  }

  # OIDC providers (both GitHub and per-EKS-cluster)
  statement {
    sid = "OIDCProvider"
    actions = [
      "iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider", "iam:UntagOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
    ]
    resources = ["*"]
  }

  # PassRole scoped to permitted prefixes and EKS-related services only
  statement {
    sid     = "PassRoleToEKS"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:role/eks-*",
      "arn:aws:iam::${var.aws_account_id}:role/sentinel-*",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com", "ec2.amazonaws.com"]
    }
  }

  # Service-linked roles required by EKS and its load balancer integration
  statement {
    sid     = "ServiceLinkedRoles"
    actions = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values = [
        "elasticloadbalancing.amazonaws.com",
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com",
        "eks-fargate.amazonaws.com",
      ]
    }
  }
}

# ── Terraform state backend ───────────────────────────────────────────────────

data "aws_iam_policy_document" "terraform_state" {
  statement {
    sid = "S3State"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "s3:ListBucket", "s3:GetBucketVersioning",
    ]
    resources = [
      "arn:aws:s3:::aws-vpc-eks-tfstate-721500739616",
      "arn:aws:s3:::aws-vpc-eks-tfstate-721500739616/*",
    ]
  }
}

# ── Attach inline policies ────────────────────────────────────────────────────

resource "aws_iam_role_policy" "vpc_networking" {
  name   = "vpc-networking"
  role   = aws_iam_role.ci.name
  policy = data.aws_iam_policy_document.vpc_networking.json
}

resource "aws_iam_role_policy" "security_groups" {
  name   = "security-groups"
  role   = aws_iam_role.ci.name
  policy = data.aws_iam_policy_document.security_groups.json
}

resource "aws_iam_role_policy" "eks" {
  name   = "eks"
  role   = aws_iam_role.ci.name
  policy = data.aws_iam_policy_document.eks.json
}

resource "aws_iam_role_policy" "iam_for_eks" {
  name   = "iam-for-eks"
  role   = aws_iam_role.ci.name
  policy = data.aws_iam_policy_document.iam_for_eks.json
}

resource "aws_iam_role_policy" "terraform_state" {
  name   = "terraform-state"
  role   = aws_iam_role.ci.name
  policy = data.aws_iam_policy_document.terraform_state.json
}