resource "aws_vpc" "cloudflow" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cloudflow-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.cloudflow.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudflow-public-1"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.cloudflow.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az

  tags = {
    Name = "cloudflow-private-1"
  }
}

resource "aws_internet_gateway" "cloudflow" {
  vpc_id = aws_vpc.cloudflow.id

  tags = {
    Name = "cloudflow-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cloudflow.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudflow.id
  }

  tags = {
    Name = "cloudflow-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "nat" {
  name        = "cloudflow-nat-sg"
  description = "Allow SSH from me and all traffic from private subnet"
  vpc_id      = aws_vpc.cloudflow.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "All traffic from private subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudflow-nat-sg"
  }
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nat.id]
  source_dest_check      = false

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y iptables
    sysctl -w net.ipv4.ip_forward=1
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-nat.conf
    IFACE=$(ip route | awk '/default/ {print $5}')
    iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
  EOF

  tags = {
    Name = "cloudflow-nat"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cloudflow.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name = "cloudflow-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_ecr_repository" "snipeit" {
  name                 = "cloudflow/snipeit"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "cloudflow-snipeit"
  }
}

resource "aws_ecr_repository" "guestbook" {
  name                 = "cloudflow/guestbook"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "cloudflow-guestbook"
  }
}