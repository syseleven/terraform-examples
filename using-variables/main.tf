variable "external_network" {
  type        = "string"
  description = "external network id for router"
}

resource "openstack_compute_keypair_v2" "kp_adminuser" {
  name       = "kp_adminuser"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLOH1KvssMlw6fMGO9XGfq+fiPjQkyBnXM5fVcBuHuAMRMxJNomdNpjps0gjypA3RNFgdoTi2fDSa7oG2k2fCLPCFbcXArOw7hgffHXaGlZmJzOxL8TtZrkwKo4z1UEunmaJ5gHAXTrl8KH+dmq0mrZYsit0SIouast5FDDF6kCASzgxr0Jz4gfwKBH03tBvDiSSpmMg1VgF6EFJwtGYk6JHt0lgYbj9RkBDhl3zyDL67YZuBfuCR5JXpAOKjXEtTZdfezFIqhH/iCCreDPct4I78p0sRUaduSmh/hL0UJ4tC2NoDuMfoIXJqwsFSRcgslh/UmQEY2TgoFcjKvS69Z"
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

resource "openstack_networking_network_v2" "net_red" {
  name           = "net_red"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_red" {
  name       = "subnet_red"
  network_id = "${openstack_networking_network_v2.net_red.id}"
  cidr       = "192.168.1.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_red" {
  name                = "router_red"
  admin_state_up      = true
  external_network_id = "${var.external_network}"
}

resource "openstack_networking_router_interface_v2" "routerint_red" {
  router_id = "${openstack_networking_router_v2.router_red.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_red.id}"
}
