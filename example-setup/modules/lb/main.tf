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

resource "openstack_compute_instance_v2" "lb_instances" {
  count           = var.num
  name            = "${var.name}${count.index}"
  image_id        = var.image
  flavor_name     = var.flavor
  security_groups = ["default", "${openstack_networking_secgroup_v2.allow_webtraffic.name}"]
  metadata        = var.metadata
  user_data = templatefile("${path.module}/cloud.cfg", {
    ssh_keys           = indent(8, "\n- ${join("\n- ", var.ssh_keys)}"),
    install_generic_sh = base64encode(file("${path.module}/scripts/install_generic.sh")),
    install_lb_sh      = base64encode(file("${path.module}/scripts/install_lb.sh"))
  })

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

resource "openstack_networking_secgroup_v2" "allow_webtraffic" {
  name        = "allow incoming web traffic"
  description = "allow incoming web traffic from anywhere"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_webtraffic.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_webtraffic.id
}

resource "openstack_networking_secgroup_rule_v2" "http8080" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_webtraffic.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_webtraffic.id
}

################################################################################
# Floating IP addresses and associations
################################################################################

resource "openstack_networking_floatingip_v2" "lb_floating_ips" {
  count = var.num
  pool  = var.public_network
}

data "openstack_networking_port_v2" "port_lb_instances" {
  count      = var.num
  device_id  = openstack_compute_instance_v2.lb_instances[count.index].id
  network_id = openstack_compute_instance_v2.lb_instances[count.index].network[0].uuid
}

resource "openstack_networking_floatingip_associate_v2" "service_floating_ip_assocs" {
  count       = var.num
  floating_ip = openstack_networking_floatingip_v2.lb_floating_ips[count.index].address
  port_id     = data.openstack_networking_port_v2.port_lb_instances[count.index].id
}

################################################################################
# Output
################################################################################

output "instance_ip" {
  value = openstack_compute_instance_v2.lb_instances.*.access_ip_v4
}
