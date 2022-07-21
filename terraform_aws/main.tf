provider "aws" {
  region = "eu-central-1"
}

#creting instance
resource "aws_instance" "example" {
  ami           = "ami-065deacbcaac64cf2"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.example.id]

  #first run
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  #replace current instance
  user_data_replace_on_change = true

  tags = {
    name = "terraform-example"
  }
}

#creating sec group
resource "aws_security_group" "example" {
  name = "terraform-exmp-inst"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


