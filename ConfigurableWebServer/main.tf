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
# Deploy a configurable web server, EC2 Instance in AWS
resource "aws_instance" "configurablewebserver" {
    # ami                       : Amazon Machine Image to run on the EC2 Instance
    # instance_type             : type of EC2 Instance to run
    # vpc_security_group_ids    : security groups for the EC2 Instance
    ami                     = "ami-48a45937"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = ["${aws_security_group.securitygroup.id}"]

    # user_data         : User Data configuration, executed when Instance is booting
    # <<-EOF ... EOF    : Terraform's heredoc syntax for multiline strings without newline characters
    user_data = <<-EOF
                #!/bin/bash
                echo "<html><head><title>Terraform - Web Server</title></head><body><h1>Hello, World</h1></body></html>" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

    # Add tags to EC2 Instance
    tags {
        Name = "terraform-configurable-web-server"
        User = "kasi"
    }
}

# Create security group to receive traffic
resource "aws_security_group" "securitygroup" {
    name = "terraform-security-group-${var.server_port}"

    # Accept all incoming TCP requests on port 8080 from CIDR block 0.0.0.0/0
    ingress {
        from_port   = "${var.server_port}"
        to_port     = "${var.server_port}"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Define input variables
# 
# Syntax:
#   variable "NAME" {
#       [CONFIG ...]
#   }
# Where:
#   description : document how the variable is used
#   default     : value for variable
#   type        : "string", "list" or "map"
# 
# Define variable for server port
variable "server_port" {
    description = "The port that server will use for HTTP requests"
    default     = 8080
}

# Define output variables
# 
# Syntax:
#     output "NAME" {
#         value = VALUE
#     }
# 
# Define output variable to find IP address of your server
output "public_ip" {
    value = "${aws_instance.configurablewebserver.public_ip}"
}