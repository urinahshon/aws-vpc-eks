resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_sg_id]
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
  }

  access_config {
    authentication_mode = var.authentication_mode
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = merge(var.tags, { Name = var.cluster_name })

  # bootstrap_cluster_creator_admin_permissions is ForceNew and only meaningful
  # at cluster creation. Ignoring it prevents a destroy-and-recreate when
  # access_config is added to a cluster that was created without this block.
  lifecycle {
    ignore_changes = [access_config[0].bootstrap_cluster_creator_admin_permissions]
  }
}

# Minimal launch template — sole purpose is attaching the pre-created node SG
# and setting disk size. Keeping SGs outside the node group resource means
# they can be referenced (e.g. in NLB health-check rules) before EKS is created.
resource "aws_launch_template" "nodes" {
  name_prefix            = "${var.cluster_name}-nodes-"
  vpc_security_group_ids = [var.node_sg_id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_instance_types

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes" })

  depends_on = [aws_eks_cluster.this]
}
