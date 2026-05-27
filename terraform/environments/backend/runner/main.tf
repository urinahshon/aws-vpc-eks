resource "aws_security_group" "runner" {
  name        = "eks-backend-gh-runner"
  description = "GitHub Actions runner - outbound-only; SSM does not need inbound"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  egress {
    description = "Allow all outbound; NAT gateway routes to GitHub and AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-backend-gh-runner" }
}

resource "aws_instance" "runner" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.runner.name
  vpc_security_group_ids = [aws_security_group.runner.id]

  user_data = base64encode(templatefile("${path.module}/runner-init.sh", {
    github_repo = var.github_repo
    github_pat  = var.github_pat
    aws_region  = var.aws_region
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  # Prevent accidental replacement when a newer AL2023 AMI is published.
  # user_data is intentionally NOT ignored: if the PAT rotates, the next apply
  # recreates the instance so the new token is used for runner re-registration.
  lifecycle {
    ignore_changes = [ami]
  }

  tags = { Name = "eks-backend-gh-runner" }
}