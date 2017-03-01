# ----------------------------------
# Common node, not to repeat myself
# ----------------------------------

variable "namespace"        { default = "enablementlab" }
variable "servername"       { }
variable "aws_amis"         { type = "map"}
variable "aws_region"       { }
variable "sshkey"           { }
variable "instance_type"    { default = "t2.micro" }
variable "public_ip"        { default = "true" }
variable "provision_script" { type = "list" }
variable "keypath"          { }
variable "sec_group"        { } 
variable "subnet_id"        { } 


resource "aws_instance" "node" {
  ami                         = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${var.subnet_id}"
  vpc_security_group_ids      = ["${var.sec_group}"]
  associate_public_ip_address = "${var.public_ip}"
  key_name                    = "${var.sshkey}"
  provisioner "remote-exec" {
    inline = "${var.provision_script}"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.keypath)}"
    }
  }
  tags {
    Name = "${var.servername}"
  }
}
