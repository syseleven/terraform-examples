resource "openstack_compute_keypair_v2" "kp_adminuser" {
  name       = "kp_adminuser"
  public_key = "${var.ssh_publickey}"
}

resource "openstack_compute_secgroup_v2" "sg_ssh" {
  name        = "sg_ssh"
  description = "Allow inboud SSH"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
