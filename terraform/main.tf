provider "aws" {
  region = var.aws_region
}

# ECR Repository
resource "aws_ecr_repository" "portfolio" {
  name                 = "portfolio"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Security Group
resource "aws_security_group" "portfolio_sg" {
  name        = "portfolio-sg"
  description = "Portfolio server security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "portfolio" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.portfolio_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y docker.io awscli
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "portfolio-server"
  }
}

# Elastic IP
resource "aws_eip" "portfolio" {
  instance = aws_instance.portfolio.id
  domain   = "vpc"
}