terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  access_key = ""
  secret_key = ""
}

# 1- default vpc
resource "aws_default_vpc" "default" {
    tags = {
        Name = "Default VPC"
    }
}

# 1- Create Security Group (SG)
# allow_web = New(aws_security_group)
resource "aws_security_group" "allow_web" {
  name = "allow_web_traffic"
  description = "Allow inbound web traffic"
  vpc_id = aws_default_vpc.default.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    "Name" = "test-sg"
  }

}

# 4- creat aws_instance 
data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}


resource "aws_instance" "nginx-server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    count = 2 # creat two instances
    vpc_security_group_ids  = [aws_security_group.allow_web.id]
    user_data = file("${path.module}/scripts/install_nginx.sh") # install nginx on both instances
    tags = {
        Name = "server-nginx-${count.index}"
    }
}

# 5 - application load Balancer
resource "aws_lb" "nginx-lb" {
    name               = "nginx-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.allow_web.id]
    subnets            = data.aws_subnet_ids.subnet_ids_nginx.ids

    enable_deletion_protection = true
     tags = {
        Environment = "nginx-lb"
    }
}

# aws subnet
data "aws_subnet_ids" "subnet_ids_nginx" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_lb_target_group" "nginx-lb" {
  name     = "tf-nginx-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

# aws gs attachment 1
resource "aws_lb_target_group_attachment" "nginx-lb-tg-attachment-1" {
  target_group_arn = aws_lb_target_group.nginx-lb.arn
  target_id        = aws_instance.nginx-server[0].id
  port             = 80
}

# aws gs attachment 2
resource "aws_lb_target_group_attachment" "nginx-lb-tg-attachment-2" {
  target_group_arn = aws_lb_target_group.nginx-lb.arn
  target_id        = aws_instance.nginx-server[1].id
  port             = 80
}

resource "aws_lb_listener" "nginx-lb" {
    load_balancer_arn = aws_lb.nginx-lb.arn
    port              = "80"
    protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-lb.arn
  }
}
