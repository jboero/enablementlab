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


resource "aws_instance" "vault-node" {
  ami                         = "${lookup(var.aws_amis, var.aws_region)}"
  count                       = "${length(var.students) * 3}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${var.subnet_id}"
  vpc_security_group_ids      = ["${var.sec_group}"]
  associate_public_ip_address = "${var.public_ip}"
  key_name                    = "${var.sshkey}"
  provisioner "file" {
    source      = "${path.module}/files/vault.zip"
    destination = "/tmp/vault.zip"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.keypath)}"
    }
  }
  provisioner "remote-exec" {
    inline = [ "/usr/bin/sudo /sbin/setenforce 0",
               "/bin/curl https://raw.githubusercontent.com/ncorrare/terraform-examples/master/provision.sh | /usr/bin/sudo /bin/bash",
               "/usr/bin/sudo FACTER_training_username=${element(var.students, count.index)} FACTER_namespace=${var.namespace} FACTER_consulserver=${var.consulserver} FACTER_vaulturl=/tmp/vault.zip /opt/puppetlabs/bin/puppet apply --environment enablementlab -e 'include profile::vault'"
                     ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.keypath)}"
    }
  }  
  tags {
    Name = "${var.servername}-${element(var.students, count.index)}-${var.namespace}-${count.index}"
  }
}
output "vault-servers" { value = ["${aws_instance.vault-node.*.public_dns}"] }
