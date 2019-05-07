resource "openstack_compute_secgroup_v2" "sg_ssh" {
  name        = "simple_sg_ssh"
  description = "Allow inbound SSH"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
