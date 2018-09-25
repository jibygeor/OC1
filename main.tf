# variable names 
variable "Devops_AMIS" {type="map"}
variable "cidr_blocks" {type="map"}
variable "AppNames" {  type="map" }
variable "layer" {type="list"}
variable "env" {}
variable "instance_types" {type="map"}
variable "name" {}
variable "poc_from_port" {}
variable "poc_to_port" {}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
}

resource "aws_vpc" "WebHarrisDemo" {
  cidr_block       = "${lookup(var.cidr_blocks,"vpc")}"
  instance_tenancy = "default"

  tags {
    Name = "WebHarrisDemoVPC"
    Location ="Kerala"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.WebHarrisDemo.id}"
  cidr_block = "${lookup(var.cidr_blocks,"subnet")}"

  tags {
    Name = "WebHarrisDemoSubnet"
  }
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}


resource "aws_security_group" "web_security_group" {
  name ="Harris_POC_web_security_group"
  vpc_id="${aws_vpc.WebHarrisDemo.id}"

ingress {
    from_port = "${var.poc_from_port}"
    to_port = "${var.poc_to_port}"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
egress {
    from_port = "${var.poc_from_port}"
    to_port = "${var.poc_to_port}"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 }

resource "aws_instance" "ec2Linux" {
 #ami                         = "${data.aws_ami.amazon-linux-2.id}"
 ami ="ami-0c7d8678e345b414c"
 associate_public_ip_address = true
 #iam_instance_profile        = "${aws_iam_instance_profile.test.id}"
 instance_type               = "t2.micro"
 key_name                    = "jenkins_master"
 vpc_security_group_ids      = ["${aws_security_group.web_security_group.id}"]
 subnet_id                   = "${aws_subnet.subnet1.id}"
 user_data = <<-EOF
              #!/bin/bash
               sudo yum update -y
               sudo yum install httpd -y
               sudo service httpd start
               echo "Harris Demo 1- Local Control Portal- Before CI Trigger" > /var/www/html/index.html
               sudo chkconfig httpd on
               hostname -f >> /var/www/html/index.html
              EOF
 tags {
    Name = "WebHarrisDemoEC2"
  }
}

output "public_ip" {
  value = "${aws_instance.ec2Linux.public_ip}"
}
#  new changes 

resource "aws_internet_gateway" "WebMgmt_igw" {
    vpc_id = "${aws_vpc.WebHarrisDemo.id}"

    tags {
        Name = "${var.name}-${var.env}-igw"
    }
}

resource "aws_route_table" "WebPublic_RT" {
    vpc_id = "${aws_vpc.WebHarrisDemo.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.WebMgmt_igw.id}"
	}
}

resource "aws_main_route_table_association" "main_route" {
    vpc_id = "${aws_vpc.WebHarrisDemo.id}"
    route_table_id = "${aws_route_table.WebPublic_RT.id}"
}	

resource "aws_route_table_association" "main_route" {
    subnet_id = "${aws_subnet.subnet1.id}"
    route_table_id = "${aws_route_table.WebPublic_RT.id}"
}


resource "aws_eip_association" "eip_assocMaster" {
  instance_id   = "${aws_instance.ec2Linux.id}"
  allocation_id = "eipalloc-0ec35d8859bb59865"
}
