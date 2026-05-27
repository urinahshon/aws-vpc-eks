data "aws_iam_policy_document" "runner_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "eks-backend-gh-runner"
  description        = "Instance role for the GitHub Actions self-hosted runner in the backend VPC"
  assume_role_policy = data.aws_iam_policy_document.runner_assume.json
}

# SSM Session Manager — shell access without a bastion or open inbound port.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner" {
  name = "eks-backend-gh-runner"
  role = aws_iam_role.runner.name
}