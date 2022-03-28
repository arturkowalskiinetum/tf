provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "sg" {
  name        = "sg"
  vpc_id      = aws_vpc.main.id
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = 3

  name                        = "ec2_instance"
  ami                         = "ami-ebd02392"
  instance_type               = "t2.nano"
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = false
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "elb"

  subnets         = [aws_subnet.main.id]
  security_groups = [aws_security_group.sg.id]

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    }
  ]

  number_of_instances = 3
  instances           = module.ec2_instances.id

}