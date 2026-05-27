variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket that holds all Terraform remote states"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/name format"
  default     = "urinahshon/aws-vpc-eks"
}

variable "github_pat" {
  type        = string
  description = "GitHub PAT (repo scope) used once at boot to register the runner"
  sensitive   = true
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}