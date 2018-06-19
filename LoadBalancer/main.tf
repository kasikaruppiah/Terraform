# Deploy infrastructure on AWS in ap-northeast-1 region
provider "aws" {
  region = "ap-northeast-1"
}

# Create an Auto Scaling Group Configuration to launch EC2 Instance in AWS
resource "aws_launch_configuration" "asgconfiguration" {
  # image_id : Amazon Machine Image to run on the EC2 Instance
  image_id        = "ami-48a45937"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.securitygroup.id}"]

  user_data = <<-EOF
                #!/bin/bash
                echo "<html><head><title>Terraform - Web Server</title></head><body><h1>Hello, World</h1></body></html>" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

  name_prefix = "tf-lc-"

  # lifecycle parameter is a meta-parameter that exists on every resource in Terraform
  # used to configure how a resource should be created, updated or destroyed
  #
  # create_before_destroy - First create a resource, wait for it to come online and then remove the old resource
  lifecycle {
    create_before_destroy = true
  }
}

# Create security group to receive traffic on 8080
resource "aws_security_group" "securitygroup" {
  name_prefix = "tf-sg-"

  # inbound request
  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound request
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Must be set at every dependent resoure to avoid cyclic dependency errors
  lifecycle {
    create_before_destroy = true
  }
}

# Define variable for server port
variable "server_port" {
  description = "The port that server will use for HTTP requests"
  default     = 80
}

# Create a ASG to launch cluster of web servers
resource "aws_autoscaling_group" "clusterwebservers" {
  launch_configuration = "${aws_launch_configuration.asgconfiguration.id}"
  availability_zones   = ["${data.aws_availability_zones.allavailabilityzones.names}"]

  # register new instances to elb
  load_balancers    = ["${aws_elb.elb.name}"]
  health_check_type = "ELB"

  min_size         = 2
  max_size         = 10
  desired_capacity = 3

  tag {
    key                 = "Name"
    value               = "tf-asg-instance"
    propagate_at_launch = true
  }
}

# Define Data Source to get all availability zones
data "aws_availability_zones" "allavailabilityzones" {}

# Create an ELB to work across all the AZ
resource "aws_elb" "elb" {
  name_prefix        = "tf-lb-"
  availability_zones = ["${data.aws_availability_zones.allavailabilityzones.names}"]
  security_groups    = ["${aws_security_group.securitygroup.id}"]

  # receive requests on http port and route them to http port
  listener {
    lb_port           = "${var.server_port}"
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  # health check to identify unhealthy instances and stop routing request
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

# output the DNS name of the ELB
output "elb_dns_name" {
  value = "${aws_elb.elb.dns_name}"
}
