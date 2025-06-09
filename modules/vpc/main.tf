data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

locals {
  az_count           = var.multi_az ? 3 : 1
  azs                = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  # VPC /16 divided in two blocks /17
  public_base_cidr   = cidrsubnet(var.vpc_cidr, 1, 0)  # 10.0.0.0/17
  private_base_cidr  = cidrsubnet(var.vpc_cidr, 1, 1)  # 10.0.128.0/17

  public_cidr_base   = range(local.az_count)
  private_cidr_base  = range(local.az_count)
}

resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.public_base_cidr, 7, local.public_cidr_base[count.index]) # /24
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = var.multi_az ? "${var.name_prefix}-public-subnet-${count.index}" : "${var.name_prefix}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.private_base_cidr, 2, local.private_cidr_base[count.index]) # /19
  availability_zone = local.azs[count.index]

  tags = {
    Name = var.multi_az ? "${var.name_prefix}-private-subnet-${count.index}" : "${var.name_prefix}-private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-vpc-igw"
  }
}

resource "aws_eip" "nat" {
  count  = var.egress_strategy == "multi" ? local.az_count : 1
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = var.egress_strategy == "multi" ? local.az_count : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = var.egress_strategy == "multi" ? "${var.name_prefix}-nat-gateway-${count.index}" : "${var.name_prefix}-nat-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = var.egress_strategy == "multi" ? local.az_count : 1
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.egress_strategy == "multi" ? "${var.name_prefix}-private-rt-${count.index}" : "${var.name_prefix}-private-rt"
  }
}

# MULTI: one NAT GW route table per AZ
resource "aws_route" "private_nat_multi" {
  count = var.egress_strategy == "multi" ? local.az_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

# SINGLE: one NAT GW route table
resource "aws_route" "private_nat_single" {
  count = var.egress_strategy == "single" ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route_table_association" "private_multi" {
  count = var.egress_strategy == "multi" ? local.az_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_single" {
  count = var.egress_strategy == "single" ? local.az_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
