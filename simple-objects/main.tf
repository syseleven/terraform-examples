resource "openstack_compute_keypair_v2" "kp_adminuser" {
  name       = "kp_adminuser"
  public_key = var.ssh_publickey
}

resource "openstack_compute_secgroup_v2" "sg_control" {
  name        = "sg_control"
  description = "Allow inbound SSH and SNMP"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 161
    to_port     = 161
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

