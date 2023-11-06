resource "openstack_compute_instance_v2" "instance_red" {
  name            = "RED Instance"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = "m2.tiny"
  key_pair        = openstack_compute_keypair_v2.kp_adminuser.name
  security_groups = [openstack_networking_secgroup_v2.sg_ssh.name, "default"]

  network {
    uuid = openstack_networking_network_v2.net_red.id
  }

  network {
    port = openstack_networking_port_v2.nfs_port_red.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_networking_floatingip_v2" "fip_red" {
  pool = var.external_network
}

resource "openstack_compute_floatingip_associate_v2" "fipas_red" {
  floating_ip = openstack_networking_floatingip_v2.fip_red.address
  instance_id = openstack_compute_instance_v2.instance_red.id
}

