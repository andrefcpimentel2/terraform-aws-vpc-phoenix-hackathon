################################################################################
# Data Sources
################################################################################
data "aws_vpc_endpoint_service" "s3_endpoint" {
  service      = "s3"
  service_type = "Gateway"
}

data "aws_region" "default" {}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "def" {
  name        = "def"
  vpc_id      = aws_vpc.main.id
  description = "def"

  ## TCP SSH NONSTD IN
  #
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ## ICMP INTERNAL INBOUND PING
  #
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.vpc_cidr] # ["10.0.0.0/16"] or equivalent
  }

  ## EXTERNAL GET TO ANYWHERE all traffic
  #
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ## ICMP INTERNAL INBOUND PING
  #
  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.vpc_cidr] # ["10.0.0.0/16"] or equivalent
  }
}

################################################################################
# VPC
################################################################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-${var.common_tags.Env}-vpc-${data.aws_region.default.region}"
    }
  )
}

################################################################################
# Subnets
################################################################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name   = "${var.prefix}-public"
    }
  )
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[0]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name   = "${var.prefix}-private"
    }
  )
}
################################################################################
# Routes
################################################################################

resource "aws_route_table" "private" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_nat_gateway.main]

  tags = merge(
    { Name = "${var.prefix}-private" },
    var.common_tags
  )
}
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table" "public" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    { Name = "${var.prefix}-public" },
    var.common_tags
  )
}
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

################################################################################
# Gateways/IPs
################################################################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    { Name = "${var.prefix}-igw" }
  )
}

resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.common_tags,
    { Name = "${var.prefix}-nat-eip" }
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  depends_on = [
    aws_internet_gateway.main,
    aws_eip.nat_eip,
    aws_subnet.public,
  ]

  tags = merge(
    var.common_tags,
    { Name = "${var.prefix}-ngw" }
  )
}

################################################################################
# VPC Endpoints
################################################################################
resource "aws_vpc_endpoint" "main" {
  vpc_id            = aws_vpc.main.id
  service_name      = data.aws_vpc_endpoint_service.s3_endpoint.service_name
  vpc_endpoint_type = "Gateway"

  tags = merge(
    var.common_tags,
    { Name = "${var.prefix}-s3-vpc-endpoint" }
  )
}

resource "aws_vpc_endpoint_route_table_association" "s3_assoc_public" {
  count           = length(var.public_subnet_cidrs)
  vpc_endpoint_id = aws_vpc_endpoint.main.id
  route_table_id  = element(aws_route_table.public.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "s3_assoc_private" {
  count           = length(var.private_subnet_cidrs)
  vpc_endpoint_id = aws_vpc_endpoint.main.id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

