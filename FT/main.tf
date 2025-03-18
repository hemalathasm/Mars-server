terraform {
  cloud {
    organization = "me_myself"

    workspaces {
      name = "Mars-server"
    }
  }
}

#1. VPC creation
resource "aws_vpc" "mars-vpc" {
  cidr_block           = var.cidr-vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "mars"
  }
}

#2. Subnet creation
resource "aws_subnet" "public-sub" {
  vpc_id            = aws_vpc.mars-vpc.id
  count             = length(var.az)
  cidr_block        = cidrsubnet(aws_vpc.mars-vpc.cidr_block, 8, count.index + 1)
  availability_zone = element(var.az, count.index)

  tags = {
    Name = "mars public subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private-sub" {
  vpc_id            = aws_vpc.mars-vpc.id
  count             = length(var.az)
  cidr_block        = cidrsubnet(aws_vpc.mars-vpc.cidr_block, 8, count.index + 3)
  availability_zone = element(var.az, count.index)

  tags = {
    Name = "mars private subnet ${count.index + 1}"
  }
}

#3. Internet gateway
resource "aws_internet_gateway" "Igw-vpc" {
  vpc_id = aws_vpc.mars-vpc.id

  tags = {
    Name = "mars"
  }
}

#4. RT for public subnet
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.mars-vpc.id
  route {
    cidr_block = var.cidr-rt
    gateway_id = aws_internet_gateway.Igw-vpc.id
  }
  tags = {
    Name = "mars"
  }
}

#5. Association between RT and public subnet
resource "aws_route_table_association" "rt-igw" {
  route_table_id = aws_route_table.rt-public.id
  count          = length(var.az)
  subnet_id      = element(aws_subnet.public-sub[*].id, count.index)
}

#6. Elastic IP
resource "aws_eip" "eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.Igw-vpc]
}

#7. NAT gateway
resource "aws_nat_gateway" "nat-gw" {
  subnet_id     = element(aws_subnet.public-sub[*].id, 0)
  allocation_id = aws_eip.eip.id
  depends_on    = [aws_internet_gateway.Igw-vpc]

  tags = {
    Name = "mars"
  }
}

#8 RT for private subnet
resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.mars-vpc.id
  route {
    cidr_block = var.cidr-rt
    gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "mars"
  }
}

#9. Association between RT and private subnet
resource "aws_route_table_association" "rt-nat" {
  route_table_id = aws_route_table.rt-private.id
  count          = length(var.az)
  subnet_id      = element(aws_subnet.private-sub[*].id, count.index)
}

