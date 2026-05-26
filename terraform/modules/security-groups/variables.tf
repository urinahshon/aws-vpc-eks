variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "additional_node_sg_ingress" {
  description = "Extra ingress rules added to the node security group (e.g. cross-VPC NLB traffic)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
