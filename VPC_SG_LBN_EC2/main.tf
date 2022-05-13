#VPC and subnets +
#Security groups +
#Load balancer (and target groups)
#EC2 running the application +

provider "aws" {
  region = local.region
}

locals {
  region = "eu-central-1"
}

##############
# VPC Module #
##############

resource "aws_vpc" "app-vpc" {
  cidr_block = "10.0.0.0/16"
  #enable_dns_support   = "true"
  #enable_dns_hostnames = "true"
  enable_classiclink = "false"
  instance_tenancy   = "default"

  tags = {
    Name = "app-vpc"
  }
}

resource "aws_subnet" "app-subnet-public-1" {
  vpc_id                  = aws_vpc.app-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "app-subnet-public-1"
  }
}

#internet gateway
resource "aws_internet_gateway" "app-igw" {
  vpc_id = aws_vpc.app-vpc.id
  tags = {
    Name = "app-igw"
  }
}

# custom route table
resource "aws_route_table" "app-public-crt" {
  vpc_id = aws_vpc.app-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0" //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.app-igw.id
  }

  tags = {
    Name = "prod-public-crt"
  }
}

resource "aws_route_table_association" "app-crta-public-subnet-1" {
  subnet_id      = aws_subnet.app-subnet-public-1.id
  route_table_id = aws_route_table.app-public-crt.id
}


#load balancer
/* resource "aws_lb" "app-lb" {
  name               = "basic-load-balancer"
  load_balancer_type = "network"
  #vpc_id = aws_vpc.app-vpc.id
  subnets            = [aws_subnet.app-subnet-public-1.id]

  #enable_cross_zone_load_balancing = true

  tags = {
      Name = "app-lb"
  }
} */



#sec groups
resource "aws_security_group" "app_port_allow" {
  vpc_id = aws_vpc.app-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
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

  tags = {
    Name = "port-allow"
  }
}

#Ec2
resource "aws_instance" "app_server" {
  ami           = "ami-05cafdf7c9f772ad2"
  instance_type = "t2.micro"

  #VPC
  subnet_id = aws_subnet.app-subnet-public-1.id

  #sec group
  vpc_security_group_ids = ["${aws_security_group.app_port_allow.id}"]

  #pub ssh key
  key_name = "./keys/app-key-pair"
  tags = {
    Name = "app_server"
  }

}

output "my-public-ip" {
  value = aws_instance.app_server.public_ip
}

// Sends your public key to the instance
resource "aws_key_pair" "app-key-pair" {
  key_name   = "./keys/app-key-pair"
  public_key = file("./keys/app-key-pair")
  }

#app
resource "null_resource" "remote" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./keys/app-key-pair")
    host        = aws_instance.app_server.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo systemctl enable httpd --now",
      ]
  }
}

