variable "name" {
  description = "Name prefix (gateway or backend)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones (one subnet per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name — used for subnet discovery tags"
  type        = string
}

variable "enable_public_elb_tag" {
  description = "Tag public subnets for internet-facing load balancers. Set false for private VPCs where no public LB should ever be created."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
