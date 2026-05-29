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

variable "authentication_mode" {
  description = "EKS cluster authentication mode. API_AND_CONFIG_MAP enables Access Entries alongside the legacy aws-auth ConfigMap."
  type        = string
  default     = "API_AND_CONFIG_MAP"
  validation {
    condition     = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "Must be one of CONFIG_MAP, API, or API_AND_CONFIG_MAP."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
