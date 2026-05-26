variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "aws_account_id" {
  description = "AWS account ID — scopes IAM write permissions to prevent cross-account privilege escalation"
  default     = "721500739616"
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repository"
  type        = string
  default     = "urinahshon"
}

variable "github_repo" {
  description = "GitHub repository name without the org prefix"
  type        = string
  default     = "aws-vpc-eks"
}

variable "create_oidc_provider" {
  description = "Set to false if the GitHub Actions OIDC provider already exists in this account"
  type        = bool
  default     = false
}