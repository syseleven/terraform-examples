###7
### SYS11 Terraform Example
### Module to create dbserver instances.
###

################################################################################
# Input variables
################################################################################

variable "count" {
  type    = "string"
  default = "1"
}

variable "name" {
  type = "string"
}

variable "syseleven_net" {
  type = "string"
}

variable "image" {
  type = "string"
}

variable "flavor" {
  type = "string"
}

variable "ssh_keys" {
  type = "list"
}

variable "metadata" {
  type = "map"
}

################################################################################
# Template cloudinit
################################################################################

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud.cfg")}"

  vars {
    # Join list of ssh keys to an indented string value usable for YAML
    ssh_keys            = "${indent(8, "\n- ${join("\n- ", var.ssh_keys)}")}"
    install_generic_sh  = "${base64encode(file("${path.module}/scripts/install_generic.sh"))}"
    install_dbserver_sh = "${base64encode(file("${path.module}/scripts/install_dbserver.sh"))}"
  }
}

################################################################################
# Instances
################################################################################

resource "openstack_compute_instance_v2" "db_instances" {
  count       = "${var.count}"
  name        = "${var.name}${count.index}"
  image_name  = "${var.image}"
  flavor_name = "${var.flavor}"
  user_data   = "${data.template_file.cloud_config.rendered}"
  metadata    = "${var.metadata}"

  network {
    name = "${var.syseleven_net}"
  }
}

################################################################################
# Output
################################################################################

output "instance_ip" {
  value = "${openstack_compute_instance_v2.db_instances.*.access_ip_v4}"
}
