variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket that holds all Terraform remote states"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}