###
### SYS11 Terraform Example
### Module to create service host, used a jumphost for management and being a
### consul server.
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
  type = list(any)
}

variable "public_network" {
  type = string
}

variable "metadata" {
  type = map(any)
}

################################################################################
# Instances
################################################################################

resource "openstack_compute_instance_v2" "service_instances" {
  count       = var.num
  name        = "${var.name}${count.index}"
  image_id    = var.image
  flavor_name = var.flavor
  metadata    = var.metadata
  user_data = templatefile("${path.module}/cloud.cfg", {
    ssh_keys              = indent(8, "\n- ${join("\n- ", var.ssh_keys)}"),
    install_generic_sh    = base64encode(file("${path.module}/scripts/install_generic.sh")),
    install_deployhost_sh = base64encode(file("${path.module}/scripts/install_deployhost.sh"))
  })

  security_groups = [
    "default",
    "${openstack_compute_secgroup_v2.allow_ssh.name}",
  ]

  network {
    uuid = var.syseleven_net
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

resource "openstack_compute_secgroup_v2" "allow_ssh" {
  name        = "allow incoming traffic, tcp"
  description = "allow incoming traffic from anywhere."

  rule {
    from_port   = 22
    to_port     = 22
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

resource "openstack_networking_floatingip_v2" "service_floating_ips" {
  count = var.num
  pool  = var.public_network
}

resource "openstack_compute_floatingip_associate_v2" "service_floating_ip_assocs" {
  count       = var.num
  floating_ip = element(openstack_networking_floatingip_v2.service_floating_ips.*.address, count.index)
  instance_id = element(openstack_compute_instance_v2.service_instances.*.id, count.index)
}

################################################################################
# Output
################################################################################

output "instance_ip" {
  value = openstack_compute_instance_v2.service_instances.*.access_ip_v4
}
