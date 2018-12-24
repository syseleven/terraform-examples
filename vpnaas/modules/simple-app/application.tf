provider "openstack" {
  region = "${var.region}"
}

data "openstack_networking_network_v2" "ext_net" {
  name = "ext-net"
}

resource "openstack_images_image_v2" "application" {
  name             = "${var.name}"
  image_source_url = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
}

resource "openstack_compute_keypair_v2" "application" {
  name       = "${var.name}"
  public_key = "${var.public_key}"
}

resource "openstack_compute_secgroup_v2" "application" {
  name        = "${var.name}"
  description = "Security Group for SSH access"

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

resource "openstack_compute_instance_v2" "application" {
  name        = "${var.name}"
  image_id    = "${openstack_images_image_v2.application.id}"
  flavor_name = "m1.tiny"
  key_pair    = "${openstack_compute_keypair_v2.application.name}"

  security_groups = [
    "default",
    "${openstack_compute_secgroup_v2.application.name}",
  ]

  network {
    name = "${var.network}"
  }
}

resource "openstack_compute_floatingip_v2" "application" {
  pool = "${data.openstack_networking_network_v2.ext_net.name}"
}

resource "openstack_compute_floatingip_associate_v2" "application" {
  floating_ip = "${openstack_compute_floatingip_v2.application.address}"
  instance_id = "${openstack_compute_instance_v2.application.id}"
}
