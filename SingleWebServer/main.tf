# Configure provider
# Deploy infrastructure on AWS in ap-northeast-1 region
provider "aws" {
  region = "ap-northeast-1"
}

# Create resources for the provider
# 
# Syntax:
#   resource "PROVIDER_TYPE" "NAME" {
#       [CONFIG ...]
#   }
# Where:
#   PROVIDER    : name of the provider
#   TYPE        : resource to create in the provider
#   NAME        : identifier to use in the Terraform Code
#   CONFIG      : one or more configuration parameters, specific to the resource
# 
# Deploy a single web server, EC2 Instance in AWS
resource "aws_instance" "singlewebserver" {
  # ami                       : Amazon Machine Image to run on the EC2 Instance
  # instance_type             : type of EC2 Instance to run
  # vpc_security_group_ids    : security groups for the EC2 Instance
  ami = "ami-48a45937"

  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.securitygroup8080.id}"]

  # user_data         : User Data configuration, executed when Instance is booting
  # <<-EOF ... EOF    : Terraform's heredoc syntax for multiline strings without newline characters
  user_data = <<-EOF
                #!/bin/bash
                echo "<html><head><title>Terraform - Web Server</title></head><body><h1>Hello, World</h1></body></html>" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

  # Add tags to EC2 Instance
  tags {
    Name = "terraform-single-web-server"
    User = "kasi"
  }
}

# Create security group to receive traffic
resource "aws_security_group" "securitygroup8080" {
  name = "terraform-security-group-8080"

  # Accept all incoming TCP requests on port 8080 from CIDR block 0.0.0.0/0
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
