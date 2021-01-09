provider “aws” {
region = “ap-southeast-2”
shared_credentials_file = “${pathexpand(“~/.aws/credentials”)}”
#shared_credentials_file = “/home/dzhang/.aws/credentials”
}
resource “aws_instance” “web1” {
ami = “ami-4ba3a328”
instance_type = “t2.micro”
vpc_security_group_ids = [“${aws_security_group.websg.id}”]
user_data = <<-EOF
#!/bin/bash
echo “hello, I am web1” >index.html
nohup busybox httpd -f -p 80 &
EOF

lifecycle {
create_before_destroy = true
}

tags {
Name = “terraform-web1”
}
}

resource “aws_instance” “web2” {
ami = “ami-4ba3a328”
instance_type = “t2.micro”
vpc_security_group_ids = [“${aws_security_group.websg.id}”]
key_name = “${aws_key_pair.myawskeypair.key_name}”
user_data = <<-EOF
#!/bin/bash
echo “hello, I am Web2” >index.html
nohup busybox httpd -f -p 80 &
EOF

lifecycle {
create_before_destroy = true
}

tags {
Name = “terraform-web2”
}
}

resource “aws_key_pair” “myawskeypair” {
key_name = “myawskeypair”
public_key = “${file(“awskey.pub”)}”
}

resource “aws_security_group” “websg” {
name = “security_group_for_web_server”
ingress {
from_port = 80
to_port = 80
protocol = “tcp”
cidr_blocks = [“0.0.0.0/0”]
}

lifecycle {
create_before_destroy = true
}
}

resource “aws_security_group_rule” “ssh” {
security_group_id = “${aws_security_group.websg.id}”
type = “ingress”
from_port = 22
to_port = 22
protocol = “tcp”
cidr_blocks = [“60.242.xxx.xxx/32”]
}

data “aws_availability_zones” “allzones” {}
resource “aws_security_group” “elbsg” {
name = “security_group_for_elb”
ingress {
from_port = 80
to_port = 80
protocol = “tcp”
cidr_blocks = [“0.0.0.0/0”]
}

egress {
from_port = 0
to_port = 0
protocol = “-1”
cidr_blocks = [“0.0.0.0/0”]
}

lifecycle {
create_before_destroy = true
}
}

resource “aws_elb” “elb1” {
name = “terraform-elb”
availability_zones = [“${data.aws_availability_zones.allzones.names}”]
security_groups = [“${aws_security_group.elbsg.id}”]

listener {
instance_port = 80
instance_protocol = “http”
lb_port = 80
lb_protocol = “http”
}
health_check {
healthy_threshold = 2
unhealthy_threshold = 2
timeout = 3
target = “HTTP:80/”
interval = 30
}

instances = [“${aws_instance.web1.id}”,”${aws_instance.web2.id}”]
cross_zone_load_balancing = true
idle_timeout = 400
connection_draining = true
connection_draining_timeout = 400

tags {
Name = “terraform-elb”
}
}

output “availabilityzones” {
value = [“${data.aws_availability_zones.allzones.names}”]
}

output “elb-dns” {
value = “${aws_elb.elb1.dns_name}”
}