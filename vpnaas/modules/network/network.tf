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
  dns_nameservers = ["37.123.105.116", "37.123.105.117"]
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
  admin_state_up = "true"
}

resource "openstack_vpnaas_endpoint_group_v2" "local" {
  name      = "${var.name} local"
  type      = "subnet"
  endpoints = ["${openstack_networking_subnet_v2.network.id}"]
  lifecycle {
    create_before_destroy = true
  }
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

output "local_endpoint_group_id" {
  value = "${openstack_vpnaas_endpoint_group_v2.local.id}"
}
