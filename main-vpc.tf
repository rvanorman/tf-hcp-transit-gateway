# Create the primary VPC
resource "aws_vpc" "primary_vpc" {
  provider = aws.primary_vpc
  cidr_block = var.primary_vpc_cidr

  tags = {
    Name        = "${var.resource_prefix}-primary-vpc"
  }
}

# Create Public Subnets for the Primary VPC
resource "aws_subnet" "primary_public_subnet_a" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = var.primary_public_subnet_a_cidr
  availability_zone = var.availability_zone_one
  tags = {
    Name          = "${var.resource_prefix}-public-subnet-a"
    Accessibility = "Public"
  }
}

resource "aws_subnet" "primary_public_subnet_b" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = var.primary_public_subnet_b_cidr
  availability_zone = var.availability_zone_two
  tags = {
    Name          = "${var.resource_prefix}-public-subnet-b"
    Accessibility = "Public"
  }
}

# Create Private Subnets for the Primary VPC.
resource "aws_subnet" "primary_private_subnet_a" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = var.primary_private_subnet_a_cidr
  availability_zone = var.availability_zone_one
  tags = {
    Name          = "${var.resource_prefix}-private-subnet-a"
    Accessibility = "Private"
  }
}

resource "aws_subnet" "primary_private_subnet_b" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = var.primary_private_subnet_b_cidr
  availability_zone = var.availability_zone_two
  tags = {
    Name          = "${var.resource_prefix}-private-subnet-b"
    Accessibility = "Private"
  }
}


# Create the Elastic IP for Nat Gateway in the Primary VPC. Used https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "primary_nat_gateway_ip" {
  vpc      = true

  tags = {
    Name          = "${var.resource_prefix}-primary-nat-gw-ip"
  }
}

# Create Internet Gateway in the Primary VPC. Used https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "primary_internet_gw" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name          = "${var.resource_prefix}-primary-internet-gw"
  }
}

# Create NAT Gateway in the Primary VPC. Used https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway 
resource "aws_nat_gateway" "primary_nat_gateway" {
  allocation_id = aws_eip.primary_nat_gateway_ip.id
  subnet_id     = aws_subnet.primary_public_subnet_a.id

  tags = {
    Name          = "${var.resource_prefix}-primary-nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.primary_internet_gw]
}

# Create the Route Table for Private Subnets in the Primary VPC. Used https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table 
resource "aws_route_table" "primary_private_route_table" {
  vpc_id = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary_nat_gateway.id
  }

  route {
    cidr_block = var.hvn_cidr
    transit_gateway_id = aws_ec2_transit_gateway.primary.id
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-private-route-table"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_nat_gateway.primary_nat_gateway]
}

# Create the Route Table for Public Subnets in the Primary VPC
resource "aws_route_table" "primary_public_route_table" {
  vpc_id = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_internet_gw.id
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-public-route-table"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.primary_internet_gw]
}

# Remove any default route associations in the Primary VPC. Used https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table 
resource "aws_default_route_table" "primary_default_route_table" {
  default_route_table_id = aws_vpc.primary_vpc.default_route_table_id

  route = []

  tags = {
    Name          = "${var.resource_prefix}-primary-default-route-table"
  }
}

# Associate Primary Private Subnets to Primary Private Route Table in the Primary VPC. Used https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "primary_private_route_table_association_a" {
  subnet_id      = aws_subnet.primary_private_subnet_a.id
  route_table_id = aws_route_table.primary_private_route_table.id
}

resource "aws_route_table_association" "primary_private_route_table_association_b" {
  subnet_id      = aws_subnet.primary_private_subnet_b.id
  route_table_id = aws_route_table.primary_private_route_table.id
}

# Associate Primary Public Subnets to Primary Public Route Table in the Primary VPC.
resource "aws_route_table_association" "primary_public_route_table_association_a" {
  subnet_id      = aws_subnet.primary_public_subnet_a.id
  route_table_id = aws_route_table.primary_public_route_table.id
}

resource "aws_route_table_association" "primary_public_route_table_association_b" {
  subnet_id      = aws_subnet.primary_public_subnet_b.id
  route_table_id = aws_route_table.primary_public_route_table.id
}