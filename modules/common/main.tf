# -----------------------------------------
# Module to provision all the common
# requirements for the enablement lab
# -----------------------------------------

variable "namespace" { default = "enablementlab" }
variable "vpc_cidr"  { }

resource "aws_vpc" "lab-${var.namespace}" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gateway-${var.namespace}" {
  vpc_id = "${aws_vpc.lab-${var.namespace}.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.lab-${var.namespace}.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gateway-${var.namespace}.id}"
}


resource "aws_subnet" "vpc_subnet-${var.namespace}" {
  vpc_id = "${aws_vpc.lab-${var.namespace}.id}"
  cidr_block = "${var.vpc_cidr}"
  map_public_ip_on_launch = false
}

resource "aws_iam_user" "vault-${var.namespace}" {
    name = "vault-${var.namespace}"
    path = "/system/"
}

resource "aws_iam_user_policy" "vault-${var.namespace}" {
    name = "vault-${var.namespace}"
    user = "${aws_iam_user.vault-${var.namespace}.name}"
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

resource "aws_iam_role" "vault_role_${var.namespace}" {
    name = "vault_role_${var.namespace}"
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

resource "aws_iam_instance_profile" "vault_profile_${var.namespace}" {
    name = "vault_profile_${var.namespace}"
    roles = ["${aws_iam_role.vault_role_${var.namespace}.name}"]
}

resource "aws_security_group" "generic" {
  name        = "Generic"
  description = "Generic Security Group for Linux Instances - Only allows SSH in"
  vpc_id      = "${aws_vpc.lab-${var.namespace}.id}"

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
    cidr_blocks = ["${aws_subnet.vpc_subnet-${var.namespace}.cidr_block}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
