variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tf_state_bucket" {
  description = "S3 bucket holding Terraform state — also used as the CodeBuild artifact staging area"
  type        = string
}