variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-west-1a", "us-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnets — used only by NAT Gateways, no ELB tags"
  type        = list(string)
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets — EKS nodes and internal NLB"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "gateway_vpc_cidr" {
  description = "CIDR of the gateway VPC — kept for reference; prefer gateway_private_subnet_cidrs for SG rules"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gateway_private_subnet_cidrs" {
  description = "Gateway private subnet CIDRs — tighter blast radius: only nodes running gateway pods can reach backend"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}