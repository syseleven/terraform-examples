resource "openstack_compute_instance_v2" "instance_blue" {
  name            = "BLUE Instance"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = var.flavor
  key_pair        = openstack_compute_keypair_v2.kp_adminuser.name
  security_groups = [openstack_networking_secgroup_v2.sg_ssh.name]

  network {
    uuid = openstack_networking_network_v2.net_blue.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_networking_floatingip_v2" "fip_blue" {
  pool = var.external_network
}

data "openstack_networking_port_v2" "port_instance_blue" {
  device_id  = openstack_compute_instance_v2.instance_blue.id
  network_id = openstack_compute_instance_v2.instance_blue.network[0].uuid
}

resource "openstack_networking_floatingip_associate_v2" "fipas_blue" {
  floating_ip = openstack_networking_floatingip_v2.fip_blue.address
  port_id     = data.openstack_networking_port_v2.port_instance_blue.id
}
