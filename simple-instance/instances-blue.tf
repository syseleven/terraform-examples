resource "openstack_compute_instance_v2" "instance_blue" {
  name            = "BLUE Instance"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = "m1.tiny"
  key_pair        = openstack_compute_keypair_v2.kp_adminuser.name
  security_groups = [openstack_networking_secgroup_v2.sg_ssh.name]

  network {
    port = openstack_networking_port_v2.port_blue.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_networking_floatingip_v2" "fip_blue" {
  pool = var.external_network
}

resource "openstack_networking_port_v2" "port_blue" {
  name           = "BLUE Port"
  network_id     = openstack_networking_network_v2.net_blue.id
  fixed_ip {
    subnet_id    = openstack_networking_subnet_v2.subnet_blue.id
  }
}

resource "openstack_networking_floatingip_associate_v2" "fipas_blue" {
  floating_ip = openstack_networking_floatingip_v2.fip_blue.address
  port_id     = openstack_networking_port_v2.port_blue.id
}

