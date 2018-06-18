# Configure provider
# Deploy infrastructure on AWS in us-east-1 region
provider "aws" {
  region = "us-east-1"
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
# Deploy a single server, EC2 Instance in AWS
resource "aws_instance" "singleserver" {
  # ami           : Amazon Machine Image to run on the EC2 Instance
  # instance_type : type of EC2 Instance to run
  ami = "ami-a4dc46db"

  instance_type = "t2.micro"

  # Add tags to EC2 Instance
  tags {
    Name = "terraform-single-server"
    User = "kasi"
  }
}
