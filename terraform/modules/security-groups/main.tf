resource "aws_security_group" "cluster" {
  name        = "sg-${var.cluster_name}-cluster"
  description = "EKS control plane security group"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "sg-${var.cluster_name}-cluster" })
}

resource "aws_security_group" "nodes" {
  name        = "sg-${var.cluster_name}-nodes"
  description = "EKS managed node group security group"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name                                        = "sg-${var.cluster_name}-nodes"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "nodes_self" {
  description              = "Allow all node-to-node communication"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "nodes_from_cluster" {
  description              = "Control plane to nodes (webhooks, exec)"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "cluster_from_nodes" {
  description              = "Nodes to API server (port 443)"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "nodes_additional" {
  count = length(var.additional_node_sg_ingress)

  description       = var.additional_node_sg_ingress[count.index].description
  type              = "ingress"
  from_port         = var.additional_node_sg_ingress[count.index].from_port
  to_port           = var.additional_node_sg_ingress[count.index].to_port
  protocol          = var.additional_node_sg_ingress[count.index].protocol
  cidr_blocks       = var.additional_node_sg_ingress[count.index].cidr_blocks
  security_group_id = aws_security_group.nodes.id
}
