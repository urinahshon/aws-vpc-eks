variable "cluster_name" {
  description = "EKS cluster name. Must start with 'eks-'. Roles are named <cluster_name>-cluster-role and <cluster_name>-node-role."
  type        = string

  validation {
    condition     = startswith(var.cluster_name, "eks-")
    error_message = "cluster_name must start with 'eks-' to satisfy the approved IAM role prefix policy."
  }
}

variable "aws_account_id" {
  description = "AWS account ID used to scope the trust policy condition (prevents confused-deputy attacks)."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}