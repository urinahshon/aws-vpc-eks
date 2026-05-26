variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "tf_state_bucket" {
  description = "S3 bucket that holds all environment state files"
  type        = string
}

variable "gateway_state_key" {
  type    = string
  default = "environments/gateway/terraform.tfstate"
}

variable "backend_state_key" {
  type    = string
  default = "environments/backend/terraform.tfstate"
}