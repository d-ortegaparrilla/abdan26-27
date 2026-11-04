# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.project_name}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.project_name}"
  }
}

# Subredes Públicas
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets["publica1"].cidr
  availability_zone       = var.public_subnets["publica1"].az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-publica-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets["publica2"].cidr
  availability_zone       = var.public_subnets["publica2"].az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-publica-2"
  }
}

# Subredes Privadas (para Mount Targets EFS)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets["privada1"].cidr
  availability_zone = var.private_subnets["privada1"].az

  tags = {
    Name = "${var.project_name}-privada-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets["privada2"].cidr
  availability_zone = var.private_subnets["privada2"].az

  tags = {
    Name = "${var.project_name}-privada-2"
  }
}

# Tabla de rutas pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-ruta-publica"
  }
}

# Asociaciones de rutas públicas
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
