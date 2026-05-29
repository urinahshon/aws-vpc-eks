locals {
  backend_cluster = "eks-backend"
  gateway_cluster = "eks-gateway"
}

resource "aws_cloudwatch_log_group" "k8s_backend" {
  name              = "/codebuild/k8s-deploy-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "k8s_gateway" {
  name              = "/codebuild/k8s-deploy-gateway"
  retention_in_days = 7
}

# Backend deploy — runs inside the backend VPC to reach the private EKS API endpoint.
resource "aws_codebuild_project" "k8s_backend" {
  name          = "k8s-deploy-backend"
  description   = "Deploy k8s workloads to the private backend EKS cluster"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 20

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "BACKEND_CLUSTER"
      value = local.backend_cluster
    }
    environment_variable {
      name  = "ARTIFACTS_BUCKET"
      value = var.tf_state_bucket
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec/k8s-deploy-backend.yml")
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  vpc_config {
    vpc_id             = data.terraform_remote_state.backend_network.outputs.vpc_id
    subnets            = data.terraform_remote_state.backend_network.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.codebuild_backend.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.k8s_backend.name
      stream_name = "build"
    }
  }

  tags = {
    Name = "k8s-deploy-backend"
  }
}

# Gateway deploy — no VPC needed; the gateway EKS API endpoint is public.
resource "aws_codebuild_project" "k8s_gateway" {
  name          = "k8s-deploy-gateway"
  description   = "Deploy k8s workloads to the public gateway EKS cluster"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 20

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "GATEWAY_CLUSTER"
      value = local.gateway_cluster
    }
    environment_variable {
      name  = "ARTIFACTS_BUCKET"
      value = var.tf_state_bucket
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec/k8s-deploy-gateway.yml")
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.k8s_gateway.name
      stream_name = "build"
    }
  }

  tags = {
    Name = "k8s-deploy-gateway"
  }
}