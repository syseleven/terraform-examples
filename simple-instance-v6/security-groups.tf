resource "openstack_networking_secgroup_v2" "sg_ssh" {
  name        = "simple_sg"
  description = "Allow inbound SSH/ICMP for IPv4 and IPv6"
}

resource "openstack_networking_secgroup_rule_v2" "sg_ipv4_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "sg_ipv4_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "sg_ipv6_tcp" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "sg_ipv6_icmp" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "icmp"
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}
