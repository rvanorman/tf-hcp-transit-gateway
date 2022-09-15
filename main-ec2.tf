# Create the AMI data point to be used for later. https://medium.com/@knoldus/fetch-the-latest-ami-in-aws-using-terraform-4ea9b95025d7
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Create the Security Group for the Jump Box
resource "aws_security_group" "primary_jump_box_sg" {
  name        = "${var.resource_prefix}-primary-jump-box-sg"
  description = "Jump Box Security Group"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "Inbound SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.jumpbox_ssh_ingress_cidr]
  }

  egress {
    description = "Communication to the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  egress {
    description      = "Communication to the World"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-jump-box-sg"
  }
}

# Create the Primary Interface for the Jump Box
resource "aws_network_interface" "primary_jump_box_interface" {
  subnet_id       = aws_subnet.primary_public_subnet_a.id
  security_groups = [aws_security_group.primary_jump_box_sg.id]

  tags = {
    Name          = "${var.resource_prefix}-primary-jump-box-network-interface"
  }
}

data "aws_network_interface" "primary_jump_box_interface_data" {
  id = aws_network_interface.primary_jump_box_interface.id
}

# Create the Jump Box Instance. 
resource "aws_instance" "primary_jump_box" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.jumpbox_instance_size
  key_name                    = var.ssh_key_name
  network_interface {
    network_interface_id = aws_network_interface.primary_jump_box_interface.id
    device_index         = 0
  }
  root_block_device {
    volume_size               = var.jumpbox_instance_storage
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-jump-box"
  }
}

# Create the Elastic IP for the Jump Box
resource "aws_eip" "primary_jump_box_public_ip" {
  instance = aws_instance.primary_jump_box.id
  vpc      = true

  tags = {
    Name          = "${var.resource_prefix}-primary-jump-box-public-ip"
  }
}

# Create the Security Group for the Vault Managment Box
resource "aws_security_group" "primary_vault_mgmt_box_sg" {
  name        = "${var.resource_prefix}-primary-vault-mgmt-box-sg"
  description = "Vault Management Box Security Group"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "Inbound SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_network_interface.primary_jump_box_interface_data.private_ip}/32"]
  }

  egress {
    description = "Communication to Vault Servers"
    from_port   = 8200
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = [var.hvn_cidr]
  }

  egress {
    description      = "Communication to the World"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-vault-mgmt-box-sg"
  }
}

# Create the Primary Interface for the Vault Managment Box
resource "aws_network_interface" "primary_vault_mgmt_box_interface" {
  subnet_id       = aws_subnet.primary_private_subnet_a.id
  security_groups = [aws_security_group.primary_vault_mgmt_box_sg.id]

  tags = {
    Name          = "${var.resource_prefix}-primary-vualt-mgmt-network-interface"
  }
}

data "aws_network_interface" "primary_vault_mgmt_box_interface_data" {
  id = aws_network_interface.primary_vault_mgmt_box_interface.id
}

# Create the Vault Managment Box Instance. 
resource "aws_instance" "primary_vault_mgmt_box" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.jumpbox_instance_size
  key_name                    = var.ssh_key_name
  network_interface {
    network_interface_id = aws_network_interface.primary_vault_mgmt_box_interface.id
    device_index         = 0
  }
  root_block_device {
    volume_size               = var.jumpbox_instance_storage
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-vault-mgmt-box"
  }
}

# Create the Security Group for the Web Application Box
resource "aws_security_group" "primary_web_app_box_sg" {
  name        = "${var.resource_prefix}-primary-web-app-box-sg"
  description = "Web Application Box Security Group"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "Inbound SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_network_interface.primary_jump_box_interface_data.private_ip}/32"]
  }

  egress {
    description = "Communication to Vault Servers"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [var.hvn_cidr]
  }

  egress {
    description      = "Communication to the World"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-web-app-box-sg"
  }
}

# Create the Primary Interface for the Web Application Box
resource "aws_network_interface" "primary_web_app_interface" {
  subnet_id       = aws_subnet.primary_private_subnet_b.id
  security_groups = [aws_security_group.primary_web_app_box_sg.id]

  tags = {
    Name          = "${var.resource_prefix}-primary-web-app-network-interface"
  }
}

data "aws_network_interface" "primary_web_app_interface_data" {
  id = aws_network_interface.primary_web_app_interface.id
}

# Create the Web Application Box Instance. 
resource "aws_instance" "primary_web_app_box" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.jumpbox_instance_size
  key_name                    = var.ssh_key_name
  network_interface {
    network_interface_id = aws_network_interface.primary_web_app_interface.id
    device_index         = 0
  }
  root_block_device {
    volume_size               = var.jumpbox_instance_storage
  }

  tags = {
    Name          = "${var.resource_prefix}-primary-web-app-box"
  }
}