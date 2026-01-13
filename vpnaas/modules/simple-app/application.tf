provider "openstack" {
  region = var.region
}

data "openstack_networking_network_v2" "ext_net" {
  name = "ext-net"
}

data "openstack_images_image_v2" "image" {
  most_recent = true

  visibility = "public"
  properties = {
    os_distro  = "ubuntu"
    os_version = "24.04"
  }
}

resource "openstack_compute_keypair_v2" "application" {
  name       = var.name
  public_key = var.public_key
}

resource "openstack_networking_secgroup_v2" "application" {
  name        = var.name
  description = "Security Group for SSH access"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.application.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.application.id
}

resource "openstack_compute_instance_v2" "application" {
  name        = var.name
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = "m1.tiny"
  key_pair    = openstack_compute_keypair_v2.application.name

  security_groups = [
    "default",
    openstack_networking_secgroup_v2.application.name,
  ]

  network {
    name = var.network
  }

  lifecycle {
    ignore_changes = [
      image_id,
    ]
  }
}

resource "openstack_networking_floatingip_v2" "application" {
  pool = data.openstack_networking_network_v2.ext_net.name
}

data "openstack_networking_port_v2" "port_instance" {
  device_id  = openstack_compute_instance_v2.application.id
  network_id = openstack_compute_instance_v2.application.network[0].uuid
}

resource "openstack_networking_floatingip_associate_v2" "application" {
  floating_ip = openstack_networking_floatingip_v2.application.address
  port_id     = data.openstack_networking_port_v2.port_instance.id
}
