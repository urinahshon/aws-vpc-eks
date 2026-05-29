data "terraform_remote_state" "backend_network" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/backend/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "backend_eks" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/backend/eks/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "gateway_eks" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/gateway/eks/terraform.tfstate"
    region = var.aws_region
  }
}