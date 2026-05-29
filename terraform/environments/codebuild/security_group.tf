# Security group for the backend CodeBuild project running inside the backend VPC.
# Allows all outbound so kubectl can reach the private EKS API and the build
# container can download kubectl from the internet via the VPC's NAT gateway.
resource "aws_security_group" "codebuild_backend" {
  name        = "codebuild-k8s-backend"
  description = "CodeBuild k8s-deploy-backend egress only"
  vpc_id      = data.terraform_remote_state.backend_network.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "codebuild-k8s-backend"
  }
}