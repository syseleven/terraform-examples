resource "openstack_compute_keypair_v2" "kp_adminuser" {
  name       = "kp_adminuser"
  public_key = var.ssh_publickey
}

resource "openstack_networking_secgroup_v2" "sg_ssh" {
  name        = "sg_ssh"
  description = "Allow inbound SSH"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}
