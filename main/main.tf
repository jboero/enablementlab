# ---------------------------
# Main Terraform Plan
# ---------------------------

module "common" {
  source = "../modules/common"

  namespace     = "${var.namespace}"
  vpc_cidr      = "${var.cidr}"
}

module "consul" {
  source = "../modules/node"
  
  namespace        = "${var.namespace}"
  servername       = "consul"
  aws_amis         = "${var.aws_amis}"
  aws_region       = "${var.aws_region}"
  sshkey           = "${var.sshkey}"
  keypath          = "${var.keypath}"
  subnet_id        = "${module.common.subnet_id}"
  instance_type    = "t2.micro"
  public_ip        = "true"
  sec_group        = "${module.common.sec_group_generic_id}"
  provision_script = [ "/usr/bin/sudo /sbin/setenforce 0",
                       "/bin/curl https://raw.githubusercontent.com/ncorrare/terraform-examples/master/provision.sh | /usr/bin/sudo /bin/bash",
                       "/usr/bin/sudo /opt/puppetlabs/bin/puppet apply -e 'include profile::consulserver'"
                     ]
}

module "directory" {
  source = "../modules/node"
  
  namespace        = "${var.namespace}"
  servername       = "directory"
  aws_amis         = "${var.aws_amis}"
  aws_region       = "${var.aws_region}"
  sshkey           = "${var.sshkey}"
  keypath          = "${var.keypath}"
  subnet_id        = "${module.common.subnet_id}"
  instance_type    = "t2.micro"
  public_ip        = "true"
  sec_group        = "${module.common.sec_group_generic_id}"
  provision_script = [ "/usr/bin/sudo /sbin/setenforce 0",
                       "/bin/curl https://raw.githubusercontent.com/ncorrare/terraform-examples/master/provision.sh | /usr/bin/sudo /bin/bash",
                       "/usr/bin/sudo /opt/puppetlabs/bin/puppet apply --environment enablementlab -e 'include profile::directory'",
                       "curl https://raw.githubusercontent.com/ncorrare/hashi-control-repo/vagrant/site/profile/files/dump.ldif > /tmp/dump.ldif && ldapadd -x -D 'cn=Manager,dc=example,dc=com' -w hashicorp -p 389 -h $(hostname) -f /tmp/dump.ldif"
                     ]
}

module "students" {
  source = "../modules/students"
  
  namespace        = "${var.namespace}"
  servername       = "vault"
  aws_amis         = "${var.aws_amis}"
  aws_region       = "${var.aws_region}"
  sshkey           = "${var.sshkey}"
  keypath          = "${var.keypath}"
  subnet_id        = "${module.common.subnet_id}"
  instance_type    = "t2.micro"
  public_ip        = "true"
  sec_group        = "${module.common.sec_group_generic_id}"
  students         = "${var.students}"
  consulserver     = "${module.consul.public_hostname}"
}
