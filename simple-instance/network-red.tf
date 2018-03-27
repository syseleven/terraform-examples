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
