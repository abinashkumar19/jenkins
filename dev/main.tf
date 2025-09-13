terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# --- Random suffix for unique resources ---
resource "random_id" "suffix" {
  byte_length = 3
}

# --- Get Default VPC ---
data "aws_vpc" "default" {
  default = true
}

# --- Security Group ---
resource "aws_security_group" "ec2_sg" {
  name        = "SG-${random_id.suffix.hex}"  # unique SG name
  description = "Allow SSH and HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "EC2SecurityGroup"
  }
}

# --- EC2 Instance ---
resource "aws_instance" "my_ec2" {
  ami                         = "ami-0b982602dbb32c5bd"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = null # Replace with your key pair if needed

  tags = {
    Name = "JenkinsAutomation"
  }
}

# --- Random suffix for unique bucket ---
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- S3 Bucket ---
resource "aws_s3_bucket" "my_bucket" {
  bucket        = "mycompany-jenkins-bucket-${random_id.bucket_suffix.hex}" 
  force_destroy = true

  tags = {
    Name        = "MyDemoBucket"
    Environment = "Dev"
  }
}

# Optional: Block all public access
resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket                  = aws_s3_bucket.my_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
