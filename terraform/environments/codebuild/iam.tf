# ── Trust policy ──────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "sentinel-codebuild-k8s-deploy"
  description        = "Assumed by CodeBuild to run kubectl against backend and gateway EKS clusters"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────

data "aws_iam_policy_document" "codebuild_logs" {
  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_logs.json
}

# ── S3 — manifest staging and artifact storage ────────────────────────────────

data "aws_iam_policy_document" "codebuild_s3" {
  statement {
    sid = "S3Artifacts"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}",
      "arn:aws:s3:::${var.tf_state_bucket}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_s3" {
  name   = "s3-artifacts"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_s3.json
}

# ── EKS — kubeconfig generation ───────────────────────────────────────────────

data "aws_iam_policy_document" "codebuild_eks" {
  statement {
    sid       = "EKSDescribe"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_eks" {
  name   = "eks-describe"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_eks.json
}

# ── EC2 VPC — required when CodeBuild runs inside a VPC ──────────────────────

data "aws_iam_policy_document" "codebuild_vpc" {
  statement {
    sid = "VPCNetworkInterface"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:CreateNetworkInterfacePermission",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_vpc" {
  name   = "vpc-network-interface"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_vpc.json
}

# ── SSM — NLB hostname handoff between builds ─────────────────────────────────

data "aws_iam_policy_document" "codebuild_ssm" {
  statement {
    sid = "SSMParams"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/codebuild/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_ssm" {
  name   = "ssm-params"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_ssm.json
}