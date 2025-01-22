output "subnet" {
  value = openstack_networking_subnet_v2.network
}

output "subnet_id" {
  value = openstack_networking_subnet_v2.network.id
}

output "network_id" {
  value = openstack_networking_network_v2.network.id
}

output "vpnservice_id" {
  value = openstack_vpnaas_service_v2.network.id
}

output "ikepolicy_id" {
  value = openstack_vpnaas_ike_policy_v2.network.id
}

output "ipsecpolicy_id" {
  value = openstack_vpnaas_ipsec_policy_v2.network.id
}

output "peer_id" {
  value = openstack_vpnaas_service_v2.network.external_v4_ip
}

output "cidr" {
  value = var.cidr
}

output "ep_subnet_endpoint_group_id" {
  value = openstack_vpnaas_endpoint_group_v2.ep_subnet.id
}

output "ep_cidr_endpoint_group_id" {
  value = openstack_vpnaas_endpoint_group_v2.ep_cidr.id
}
