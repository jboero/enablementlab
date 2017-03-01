# -----------------------------------------
# Module to provision all the common
# requirements for the enablement lab
# -----------------------------------------

variable "namespace" { default = "enablementlab" }
variable "vpc_cidr"  { }

resource "aws_vpc" "lab" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
}


resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.lab.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.lab.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gateway.id}"
}

resource "aws_subnet" "vpc_subnet_lab" {
  vpc_id = "${aws_vpc.lab.id}"
  cidr_block = "${var.vpc_cidr}"
  map_public_ip_on_launch = false
}

output "subnet_id" { value = "${aws_subnet.vpc_subnet_lab.id}" }

resource "aws_iam_user" "vault-enablementlab" {
    name = "vault-enablementlab"
    path = "/system/"
}

resource "aws_iam_user_policy" "vault-enablementlab" {
    name = "vault-enablementlab"
    user = "${aws_iam_user.vault-enablementlab.name}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "iam:GetInstanceProfile"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "vault_role_enablementlab" {
    name = "vault_role_enablementlab"
    path = "/"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "vault_profile_enablementlab" {
    name = "vault_profile_enablementlab"
    roles = ["${aws_iam_role.vault_role_enablementlab.name}"]
}

resource "aws_security_group" "generic" {
  name        = "Generic"
  description = "Generic Security Group for Linux Instances - Only allows SSH in"
  vpc_id      = "${aws_vpc.lab.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Access from the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_subnet.vpc_subnet_lab.cidr_block}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output sec_group_generic_id { value = "${aws_security_group.generic.id}" }
