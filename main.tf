provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  instance_type = "t2.micro"

  tags = {
    Name = "portfolio-instance"
  }
}
