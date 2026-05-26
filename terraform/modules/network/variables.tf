variable "name" {
  description = "Name prefix (gateway or backend)"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs — one NAT gateway is placed in each"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs — one route table per AZ, pointing to its local NAT"
  type        = list(string)
}

variable "internet_gateway_id" {
  description = "Internet Gateway ID attached to the VPC"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}