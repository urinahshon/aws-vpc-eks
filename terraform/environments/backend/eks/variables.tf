variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "kubernetes_version" {
  type    = string
  default = "1.32"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "aws_account_id" {
  description = "AWS account ID — used to scope the IRSA Secrets Manager policy"
  type        = string
}

variable "tf_state_bucket" {
  description = "S3 bucket holding Terraform state — used to read network and iam outputs"
  type        = string
}