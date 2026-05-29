resource "aws_security_group" "bastion" {
  name        = "eks-gateway-bastion"
  description = "Bastion - outbound-only; SSM Session Manager needs no inbound ports"
  vpc_id      = data.terraform_remote_state.gateway_network.outputs.vpc_id

  egress {
    description = "Allow all outbound (SSM VPC endpoints + NAT for package updates)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "eks-gateway-bastion" }
}

resource "aws_security_group_rule" "bastion_to_gateway_eks_api" {
  description              = "Bastion to gateway EKS API server (kubectl)"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = data.terraform_remote_state.gateway_network.outputs.cluster_sg_id
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.gateway_network.outputs.private_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = { Name = "eks-gateway-bastion" }
}