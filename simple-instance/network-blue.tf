resource "openstack_networking_network_v2" "net_blue" {
  name           = "net_blue"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_blue" {
  name       = "subnet_blue"
  network_id = "${openstack_networking_network_v2.net_blue.id}"
  cidr       = "192.168.2.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_blue" {
  name                = "router_blue"
  admin_state_up      = true
  external_network_id = "${var.external_network}"
}

resource "openstack_networking_router_interface_v2" "routerint_blue" {
  router_id = "${openstack_networking_router_v2.router_blue.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_blue.id}"
}
