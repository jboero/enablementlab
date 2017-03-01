variable "namespace" {
  description = "Namespace to use. This string will be used to identify the resources created that are aligned to each lab"
}


variable "aws_region" {
  description = "The AWS region to create resources in."
  default     = "eu-west-1"
}


variable "aws_amis" {
  description = "The RHEL 7 image for a couple of different regions"
  default = {
    eu-west-1 = "ami-8b8c57f8"
    us-west-1 = "ami-d1315fb1"
    us-west-2 = "ami-775e4f16"
  }
}

variable "cidr" {
  description = "Subnet to be used for internal comms"
  default     = "172.16.0.0/16"
}

variable "sshkey" {
  description = "Name of the SSH Key Pair (in aws) used to login into the systems"
  default     = "nico-mbook-pub"
}

variable "keypath" {
  description = "Path to the SSH private key used to login into the systems"
  default     = "/Users/ncorrare/.ssh/id_rsa"
}

variable "awsaccountid" {
  description = "AWS Account ID"
}
