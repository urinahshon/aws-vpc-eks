variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "aws_account_id" {
  description = "AWS account ID — scopes IAM trust policy conditions to prevent confused-deputy attacks"
  type        = string
}