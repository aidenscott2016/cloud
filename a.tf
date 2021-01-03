# terraform {
#   required_providers {

#     aws = {
#       source = "hashicorp/aws"
#       version = "~> 2.70"
#     }
#   }
# }

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}



# resource "aws_eip" "ip" {
#   vpc      = true
#   instance = aws_instance.example.id
# }

# output "ip" {
#   value = aws_eip.ip.public_ip
# }

# resource "aws_db_instance" "default" {
#   allocated_storage = 20
#   # subnet_id            = "subnet-0415f730f81756be0"
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   name                 = "mydb"
#   username             = "foo"
#   password             = "foobarbaz"
#   parameter_group_name = "default.mysql5.7"
# }


resource "aws_vpc" "nc-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "nextcloud-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "nextcloud-public-subnet"
  }
}


resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "production"
  }
}

resource "aws_instance" "example" {

  ami           = "ami-06178cf087598769c"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.allow_http.id]
}


resource "aws_security_group" "allow_http" {
  name        = "nc-allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.nc-vpc.id

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.nc-vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}
