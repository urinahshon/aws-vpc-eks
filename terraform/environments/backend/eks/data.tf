data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "environments/backend/network/terraform.tfstate"
    region = var.aws_region
  }
}