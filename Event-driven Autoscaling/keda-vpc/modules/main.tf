# -------------VPC-------------
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}


# -------------public subnet------------- 
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_a_cidr

  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_a_name
  }
}
resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_b_cidr

  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_b_name
  }
}


# -------------private subnet-------------
resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_a_cidr

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = var.private_subnet_a_name
  }
}
resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_b_cidr

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = var.private_subnet_b_name
  }
}


# -------------internet gateway-------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw_name
  }
}


# -------------nat gateway-------------
resource "aws_eip" "nat_a_eip" {
}
resource "aws_eip" "nat_b_eip" {
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = var.nat_a_name
  }

  depends_on = [aws_eip.nat_a_eip]
}
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b_eip.id
  subnet_id     = aws_subnet.public_subnet_b.id

  tags = {
    Name = var.nat_b_name
  }

  depends_on = [aws_eip.nat_b_eip]
}


# -------------public route table-------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.public_rt_name
  }
}


# -------------private route table-------------
resource "aws_route_table" "private_a_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = var.private_a_rt_name
  }
}
resource "aws_route_table" "private_b_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = var.private_b_rt_name
  }
}


# ---route table association---
resource "aws_route_table_association" "public_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "private_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_a_rt.id
}
resource "aws_route_table_association" "private_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_b_rt.id
}