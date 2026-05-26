variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "subnet_ids" {
  description = "Private subnet IDs for control plane ENIs and node group"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "Security group ID for the EKS control plane (from security-groups module)"
  type        = string
}

variable "node_sg_id" {
  description = "Security group ID for the managed node group (from security-groups module)"
  type        = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  type    = number
  default = 20
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint. Required for GitHub Actions runners; restrict to known CIDRs in production."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
