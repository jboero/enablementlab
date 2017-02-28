# ----------------------------------
# Common node, not to repeat myself
# ----------------------------------

variable "namespace"        { default = "enablementlab" }
variable "servername"       { }
variable "aws_amis"         { }
variable "aws_region"       { }
variable "sshkey"           { }
variable "keypath"          { }
variable "instance_type"    { default = "t2.micro" }
variable "public_ip"        { default = "true" }
variable "provision_script" { default = [ ] }
variable "keypath"          { }

resource "aws_instance" "${var.servername}" {
  ami                         = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${aws_subnet.vpc_subnet-${var.namespace}.id}"
  vpc_security_group_ids      = ["${aws_security_group.generic.id}"]
  associate_public_ip_address = "${var.public_ip}"
  key_name                    = "${var.sshkey}"
  provisioner "remote-exec" {
    inline = ${var.provision_script}
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.keypath)}"
    }
  }
}
