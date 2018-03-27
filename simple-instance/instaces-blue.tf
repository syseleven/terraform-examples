resource "openstack_compute_instance_v2" "instance_blue" {
  name            = "BLUE Instance"
  image_id        = "${var.base_image}"
  flavor_name     = "m1.micro"
  key_pair        = "${openstack_compute_keypair_v2.kp_adminuser.name}"
  security_groups = ["${openstack_compute_secgroup_v2.sg_ssh.name}"]

  network {
    name = "${openstack_networking_network_v2.net_blue.name}"
  }
}

resource "openstack_compute_floatingip_v2" "fip_blue" {
  pool = "ext-net"
}

resource "openstack_compute_floatingip_associate_v2" "fipas_blue" {
  floating_ip = "${openstack_compute_floatingip_v2.fip_blue.address}"
  instance_id = "${openstack_compute_instance_v2.instance_blue.id}"
}
