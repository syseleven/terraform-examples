provider "openstack" {
  region = "${var.region}"
}

data "openstack_networking_network_v2" "ext_net" {
  name = "ext-net"
}

resource "openstack_networking_network_v2" "network" {
  name           = "${var.name}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "network" {
  name            = "${var.name}"
  network_id      = "${openstack_networking_network_v2.network.id}"
  cidr            = "${var.cidr}"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_router_v2" "network" {
  name                = "${var.name}"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.ext_net.id}"
}

resource "openstack_networking_router_interface_v2" "network" {
  router_id = "${openstack_networking_router_v2.network.id}"
  subnet_id = "${openstack_networking_subnet_v2.network.id}"
}

resource "openstack_vpnaas_ike_policy_v2" "network" {
  name = "${var.name}"
}

resource "openstack_vpnaas_ipsec_policy_v2" "network" {
  name = "${var.name}"
}

resource "openstack_vpnaas_service_v2" "network" {
  depends_on     = ["openstack_networking_router_interface_v2.network"]
  name           = "${var.name}"
  router_id      = "${openstack_networking_router_v2.network.id}"
  subnet_id      = "${openstack_networking_subnet_v2.network.id}"
  admin_state_up = "true"
}

output "vpnservice_id" {
  value = "${openstack_vpnaas_service_v2.network.id}"
}

output "ikepolicy_id" {
  value = "${openstack_vpnaas_ike_policy_v2.network.id}"
}

output "ipsecpolicy_id" {
  value = "${openstack_vpnaas_ipsec_policy_v2.network.id}"
}

output "peer_id" {
  value = "${openstack_vpnaas_service_v2.network.external_v4_ip}"
}

output "cidr" {
  value = "${var.cidr}"
}
