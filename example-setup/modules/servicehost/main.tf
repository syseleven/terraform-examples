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
    "${openstack_networking_secgroup_v2.allow_ssh.name}",
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

resource "openstack_networking_secgroup_v2" "allow_ssh" {
  name        = "allow_ssh_and_icmp"
  description = "Allow inbound SSH/ICMP for IPv4"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_ssh.id
}

################################################################################
# Floating IP addresses and associations
################################################################################

resource "openstack_networking_floatingip_v2" "service_floating_ips" {
  count = var.num
  pool  = var.public_network
}

data "openstack_networking_port_v2" "port_service_instances" {
  count      = var.num
  device_id  = openstack_compute_instance_v2.service_instances[count.index].id
  network_id = openstack_compute_instance_v2.service_instances[count.index].network[0].uuid
}

resource "openstack_networking_floatingip_associate_v2" "service_floating_ip_assocs" {
  count       = var.num
  floating_ip = openstack_networking_floatingip_v2.service_floating_ips[count.index].address
  port_id     = data.openstack_networking_port_v2.port_service_instances[count.index].id
}

################################################################################
# Output
################################################################################

output "instance_ip" {
  value = openstack_compute_instance_v2.service_instances.*.access_ip_v4
}
