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
  vpc_id     = aws_vpc.nc-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone  = "eu-west-2a"

  tags = {
    Name = "nextcloud-public-subnet"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.nc-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone  = "eu-west-2b"

  tags = {
    Name = "nextcloud-public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.nc-vpc.id
  tags = {
    Name = "nc igw"
  }
}

resource "aws_lb" "nc-lb" {
  name               = "nc-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]
  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  # tags = {
  #   Environment = "production"
  # }
}

resource "aws_lb_listener" "nc-lb-listener" {
  load_balancer_arn = aws_lb.nc-lb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

# resource "aws_instance" "example" {

#   ami           = "ami-06178cf087598769c"
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.private.id
#   vpc_security_group_ids = [aws_security_group.allow_http.id]
# }


resource "aws_security_group" "allow_http" {
  name        = "nc-allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.nc-vpc.id

  ingress {
    description = "http from VPC"
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
    Name = "allow_http"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.nc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "nc rt"
  }
}

output "elb_hostname" {
  value = aws_lb.nc-lb.dns_name
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.r.id
}
