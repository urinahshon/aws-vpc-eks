data "aws_iam_policy_document" "debug_ssm_assume" {
  statement {
    sid     = "AllowUserAssume"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::721500739616:user/urinahshon@gmail.com"]
    }
  }
}

resource "aws_iam_role" "debug_ssm" {
  name               = "eks-debug-ssm"
  description        = "Temporary role for SSM session access to the gateway EC2 instance"
  assume_role_policy = data.aws_iam_policy_document.debug_ssm_assume.json
}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    sid = "SSMSession"
    actions = [
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:ResumeSession",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
    ]
    resources = ["*"]
  }

  statement {
    sid = "EC2Describe"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ssm_access" {
  name   = "ssm-access"
  role   = aws_iam_role.debug_ssm.name

  policy = data.aws_iam_policy_document.ssm_access.json
}