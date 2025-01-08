terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"  # Mumbai region
}

# VPC
resource "aws_vpc" "portfolio_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "portfolio-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "portfolio_public_subnet" {
  vpc_id                  = aws_vpc.portfolio_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "portfolio-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "portfolio_igw" {
  vpc_id = aws_vpc.portfolio_vpc.id

  tags = {
    Name = "portfolio-igw"
  }
}

# Route Table
resource "aws_route_table" "portfolio_public_rt" {
  vpc_id = aws_vpc.portfolio_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.portfolio_igw.id
  }

  tags = {
    Name = "portfolio-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "portfolio_public_rt_assoc" {
  subnet_id      = aws_subnet.portfolio_public_subnet.id
  route_table_id = aws_route_table.portfolio_public_rt.id
}

# Security Group
resource "aws_security_group" "portfolio_sg" {
  name        = "portfolio-sg"
  description = "Security group for portfolio website"
  vpc_id      = aws_vpc.portfolio_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "portfolio-sg"
  }
}

# EC2 Instance
resource "aws_instance" "portfolio_instance" {
  ami           = "ami-0f5ee92e2d63afc18"  # Amazon Linux 2 AMI ID for ap-south-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.portfolio_public_subnet.id

  vpc_security_group_ids = [aws_security_group.portfolio_sg.id]
  key_name              = "portfolio-key"  # Make sure to create this key pair in AWS first

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              EOF

  tags = {
    Name = "portfolio-instance"
  }
}

# Output the public IP
output "public_ip" {
  value = aws_instance.portfolio_instance.public_ip
}