variable "prj_name" {}
variable "region" {}
variable "vpc_cidr" {}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "${var.prj_name}-vpc"
  }
}

resource "aws_subnet" "subnet_public_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0)
  availability_zone = "${var.region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prj_name}-subnet-public-c"
  }
}

resource "aws_subnet" "subnet_public_d" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)
  availability_zone = "${var.region}d"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prj_name}-subnet-public-d"
  }
}

resource "aws_subnet" "subnet_private_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)
  availability_zone = "${var.region}c"

  tags = {
    Name = "${var.prj_name}-subnet-private-c"
  }
}

resource "aws_subnet" "subnet_private_d" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3)
  availability_zone = "${var.region}d"

  tags = {
    Name = "${var.prj_name}-subnet-private-d"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prj_name}-igw"
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prj_name}-rtb-public"
  }
}

resource "aws_route_table_association" "rtb_assoc_public_c" {
  route_table_id = aws_route_table.rtb_public.id
  subnet_id      = aws_subnet.subnet_public_c.id
}

resource "aws_route_table_association" "rtb_assoc_public_d" {
  route_table_id = aws_route_table.rtb_public.id
  subnet_id      = aws_subnet.subnet_public_d.id
}

resource "aws_route" "route_igw" {
  route_table_id         = aws_route_table.rtb_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway.igw]
}

resource "aws_route_table" "rtb_private_c" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prj_name}-rtb-private-c"
  }
}

resource "aws_route_table" "rtb_private_d" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prj_name}-rtb-private-d"
  }
}

resource "aws_route_table_association" "rtb_assoc_private_c" {
  route_table_id = aws_route_table.rtb_private_c.id
  subnet_id      = aws_subnet.subnet_private_c.id
}

resource "aws_route_table_association" "rtb_assoc_private_d" {
  route_table_id = aws_route_table.rtb_private_d.id
  subnet_id      = aws_subnet.subnet_private_d.id
}

resource "aws_eip" "eip_natgw_c" {
  vpc = true

  tags = {
    Name = "${var.prj_name}-eip-natgw-c"
  }
}
resource "aws_eip" "eip_natgw_d" {
  vpc = true

  tags = {
    Name = "${var.prj_name}-eip-natgw-d"
  }
}

resource "aws_nat_gateway" "natgw_c" {
  allocation_id = aws_eip.eip_natgw_c.id
  subnet_id     = aws_subnet.subnet_public_c.id

  tags = {
    Name = "${var.prj_name}-natgw-c"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "natgw_d" {
  allocation_id = aws_eip.eip_natgw_d.id
  subnet_id     = aws_subnet.subnet_public_d.id

  tags = {
    Name = "${var.prj_name}-natgw-d"
  }

  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route" "route_natgw_c" {
  route_table_id         = aws_route_table.rtb_private_c.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.natgw_c.id
  depends_on             = [aws_nat_gateway.natgw_c]
}

resource "aws_route" "route_natgw_d" {
  route_table_id         = aws_route_table.rtb_private_d.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.natgw_d.id
  depends_on             = [aws_nat_gateway.natgw_d]
}

output vpc_id {
  value = aws_vpc.vpc.id
}
output vpc_cidr {
  value = aws_vpc.vpc.cidr_block
}
output public_subnet_ids {
  value = [aws_subnet.subnet_public_c.id, aws_subnet.subnet_public_d.id]
}
output private_subnet_ids {
  value = [aws_subnet.subnet_private_c.id, aws_subnet.subnet_private_d.id]
}
output public_route_table_id {
  value = aws_route_table.rtb_public.id
}
output private_route_table_ids {
  value = [aws_route_table.rtb_private_c.id, aws_route_table.rtb_private_d.id]
}