resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = "vpc-${var.name}" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "igw-${var.name}" })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  # kubernetes.io/role/elb is only set when internet-facing LBs are permitted.
  # Backend VPC sets enable_public_elb_tag = false to prevent accidental public exposure.
  tags = merge(
    var.tags,
    {
      Name                                        = "subnet-${var.name}-public-${var.azs[count.index]}"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
    var.enable_public_elb_tag ? { "kubernetes.io/role/elb" = "1" } : {}
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name                                        = "subnet-${var.name}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}