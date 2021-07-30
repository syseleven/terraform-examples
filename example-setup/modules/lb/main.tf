###
### SYS11 Terraform Example
### Module to create outside facing http load balancer.
###

################################################################################
# Input variables
################################################################################

variable "num" {
  type    = string
  default = "1"
}

variable "name" {
  type = string
}

variable "syseleven_net" {
  type = string
}

variable "image" {
  type = string
}

variable "flavor" {
  type = string
}

variable "ssh_keys" {
  type = list
}

variable "public_network" {
  type = string
}

variable "metadata" {
  type = map
}

################################################################################
# Template cloudinit
################################################################################

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud.cfg")}"

  vars = {
    ssh_keys           = "${indent(8, "\n- ${join("\n- ", var.ssh_keys)}")}"
    install_generic_sh = "${base64encode(file("${path.module}/scripts/install_generic.sh"))}"
    install_lb_sh      = "${base64encode(file("${path.module}/scripts/install_lb.sh"))}"
  }
}

################################################################################
# Instances
################################################################################

resource "openstack_compute_instance_v2" "lb_instances" {
  count           = "${var.num}"
  name            = "${var.name}${count.index}"
  image_id        = "${var.image}"
  flavor_name     = "${var.flavor}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.allow_webtraffic.name}"]
  user_data       = "${data.template_file.cloud_config.rendered}"
  metadata        = "${var.metadata}"

  network {
    uuid = "${var.syseleven_net}"
  }

  lifecycle {
    ignore_changes = [
      image_id,
    ]
  }
}

################################################################################
# Custom security group
################################################################################

resource "openstack_compute_secgroup_v2" "allow_webtraffic" {
  name        = "allow incoming web traffic"
  description = "allow incoming web traffic from anywhere"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 8080
    to_port     = 8080
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

################################################################################
# Floating IP addresses and associations
################################################################################

resource "openstack_compute_floatingip_v2" "lb_floating_ips" {
  count = "${var.num}"
  pool  = "${var.public_network}"
}

resource "openstack_compute_floatingip_associate_v2" "service_floating_ip_assocs" {
  count       = "${var.num}"
  floating_ip = "${element(openstack_compute_floatingip_v2.lb_floating_ips.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.lb_instances.*.id, count.index)}"
}

################################################################################
# Output
################################################################################

output "instance_ip" {
  value = "${openstack_compute_instance_v2.lb_instances.*.access_ip_v4}"
}
