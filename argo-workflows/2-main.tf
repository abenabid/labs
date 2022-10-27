module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "3.13.0"

  name = "workshop"
  cidr = "10.0.0.0/16"

  azs               = ["us-east-1a"]
  public_subnets    = ["10.0.1.0/24"]
  private_subnets  = ["10.0.11.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
}

# SSL key pair
resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS SSH key pair
resource "aws_key_pair" "key" {
  key_name   = "workshop-key"
  public_key = tls_private_key.tls_key.public_key_openssh
  
  # Save private key to local computer
  provisioner "local-exec" {
    command = "echo '${tls_private_key.tls_key.private_key_pem}' > ~/workshop-key.pem; chmod 600 ~/.ssh/workshop-key.pem"
  }
}

# Find the latest "Ubuntu 20.04 Server" image
data "aws_ami" "instance-image" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "allow_all_from_vpc" {
  name        = "allow_all_from_vpc"
  description = "Autoriser tous les flux depuis le VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Autoriser le flux HTTP entrant"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP non-restreint"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Autoriser le flux SSH entrant"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "SSH non-restreint"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
