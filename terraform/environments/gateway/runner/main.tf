resource "aws_security_group" "runner" {
  name        = "eks-backend-gh-runner"
  description = "GitHub Actions runner - outbound-only; SSM does not need inbound"
  vpc_id      = data.terraform_remote_state.gateway_network.outputs.vpc_id

  egress {
    description = "Allow all outbound; IGW/NAT routes to GitHub and AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-backend-gh-runner" }
}

# Allow the runner to reach the backend EKS private API endpoint so kubectl works.
# Cross-VPC peering: source_security_group_id cannot span VPCs, so we use the
# gateway VPC CIDR as the source.
resource "aws_security_group_rule" "runner_to_cluster_api" {
  description       = "GitHub Actions runner (gateway VPC) to backend EKS API server (kubectl port 443)"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.gateway_network.outputs.vpc_cidr]
  security_group_id = data.terraform_remote_state.backend_network.outputs.cluster_sg_id
}

resource "aws_instance" "runner" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.gateway_network.outputs.private_subnet_ids[0]
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

  lifecycle {
    ignore_changes = [ami]
  }

  tags = { Name = "eks-backend-gh-runner" }
}