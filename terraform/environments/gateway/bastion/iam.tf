data "aws_iam_policy_document" "bastion_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "eks-gateway-bastion"
  description        = "Instance role for the gateway bastion - SSM Session Manager access only"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "eks_describe" {
  statement {
    sid       = "EKSDescribe"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_describe" {
  name   = "eks-describe"
  role   = aws_iam_role.bastion.name
  policy = data.aws_iam_policy_document.eks_describe.json
}

resource "aws_iam_instance_profile" "bastion" {
  name = "eks-gateway-bastion"
  role = aws_iam_role.bastion.name
}