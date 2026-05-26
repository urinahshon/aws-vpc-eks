data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/gateway/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/gateway/iam/terraform.tfstate"
    region = var.aws_region
  }
}