terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # bucket and region are passed by the workflow (terraform init -backend-config=...)
  backend "s3" {
    key = "aws/ec2-deploy/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------
# Network: use the account's default VPC instead of an undefined aws_vpc.main
# ---------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------------------------------------------
# Latest Ubuntu 22.04 LTS AMI for the chosen region (owner = Canonical)
# Avoids a hard-coded AMI ID that only exists in one region.
# ---------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------
# EC2 instance
# ---------------------------------------------------------------
resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.mainsg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # Installs Docker on first boot so the deploy job can run the container
  user_data = file("${path.module}/user_data.sh")

  # Only used by provisioners (remote-exec / file). Harmless without one.
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = var.private_key
    timeout     = "4m"
  }

  tags = {
    Name = "DeployVM"
  }
}

# ---------------------------------------------------------------
# IAM: EC2 needs an *instance profile* wrapping the role, not the role name
# ---------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------------------------------------------------
# Security group
# ---------------------------------------------------------------
resource "aws_security_group" "mainsg" {
  name        = "allow_ssh"
  description = "Allow SSH and app traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "App"
    from_port   = 8080
    to_port     = 8080
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

# ---------------------------------------------------------------
# SSH key pair (public key comes from the AWS_SSH_KEY_PUBLIC secret)
# ---------------------------------------------------------------
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}
