provider "aws" {
  region = var.region
  profile = "default"
}

resource "aws_key_pair" "devops_key" {
  key_name   = var.key_name
  public_key = file("../keys/id_rsa.pub")
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.main.id

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
}

resource "aws_instance" "controller" {
  ami                         = "ami-04ec97dc75ac850b1" # Ubuntu 22.04 us-east-1
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.devops_key.key_name
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  tags = {
    Name = "controller"
    Role = "ansible-controller"
  }
}

resource "aws_instance" "targets" {
  count                       = 2
  ami                         = "ami-04ec97dc75ac850b1"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.devops_key.key_name
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  tags = {
    Name = "target-${count.index + 1}"
    Role = "ansible-target"
  }
}
