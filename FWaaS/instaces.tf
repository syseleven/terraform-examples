data "openstack_images_image_v2" "image" {
  most_recent = true

  visibility = "public"
  properties = {
    os_distro  = "ubuntu"
    os_version = "16.04"
  }
}

resource "openstack_compute_instance_v2" "instance_red" {
  name            = "RED Instance"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = "m1.micro"
  key_pair        = openstack_compute_keypair_v2.kp_adminuser.name
  security_groups = [openstack_compute_secgroup_v2.sg_ssh.name]

  network {
    name = openstack_networking_network_v2.net_red.name
  }
}

resource "openstack_compute_floatingip_v2" "fip_red" {
  pool = "ext-net"
}

resource "openstack_compute_floatingip_associate_v2" "fipas_red" {
  floating_ip = openstack_compute_floatingip_v2.fip_red.address
  instance_id = openstack_compute_instance_v2.instance_red.id
}

resource "openstack_compute_instance_v2" "instance_blue" {
  name            = "BLUE Instance"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = "m1.micro"
  key_pair        = openstack_compute_keypair_v2.kp_adminuser.name
  security_groups = [openstack_compute_secgroup_v2.sg_ssh.name]

  network {
    name = openstack_networking_network_v2.net_blue.name
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_floatingip_v2" "fip_blue" {
  pool = "ext-net"
}

resource "openstack_compute_floatingip_associate_v2" "fipas_blue" {
  floating_ip = openstack_compute_floatingip_v2.fip_blue.address
  instance_id = openstack_compute_instance_v2.instance_blue.id
}

