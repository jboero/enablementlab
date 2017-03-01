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
variable "keypath"          { }
variable "sec_group"        { } 
variable "subnet_id"        { } 
variable "students"         { type = "list" } 
variable "consulserver"     { } 

#data "template_file" "workstation" {
#  count    = "${var.students}"
#  template = "${file("templates/init.sh.tpl")}"
#
#  vars {
#    namespace    = "${var.namespace}"
#    servername   = "${var.servername}-${element(var.students, count.index)}-${var.namespace}-${count.index}}"
#    count        = "${count.index}"
#    username     = "${element(var.students, count.index)}"
#    consulserver = "${var.consulserver}"
#
#  }
#}

resource "aws_instance" "vault-node" {
  ami                         = "${lookup(var.aws_amis, var.aws_region)}"
  count                       = "${length(var.students) * 3}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${var.subnet_id}"
  vpc_security_group_ids      = ["${var.sec_group}"]
  associate_public_ip_address = "${var.public_ip}"
  key_name                    = "${var.sshkey}"
  tags {
    Name = "${var.servername}-${element(var.students, count.index)}-${var.namespace}-${count.index}"
  }
#    user_data = "${element(data.template_file.workstation.*.rendered, count.index)}"
}
output "vault-servers" { value = "${aws_instance.vault-node.public_dns}" }
