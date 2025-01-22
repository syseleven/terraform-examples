# Provider Configuration
provider "openstack" {
  region = var.region
}

data "openstack_networking_network_v2" "ext_net" {
  name = "ext-net"
}

# Create Network and Subnet
resource "openstack_networking_network_v2" "network" {
  name           = var.name
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "network" {
  name            = var.name
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Create Network Router
resource "openstack_networking_router_v2" "network" {
  name                = var.name
  admin_state_up      = "true"
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_router_interface_v2" "network" {
  router_id = openstack_networking_router_v2.network.id
  subnet_id = openstack_networking_subnet_v2.network.id
}

# Create VPN IKE Policy
resource "openstack_vpnaas_ike_policy_v2" "network" {
  name                 = var.name
  ike_version          = "v2"
  auth_algorithm       = "sha256"
  encryption_algorithm = "aes-256"
  pfs                  = "group14"
}

# Create VPN IPSEC Policy
resource "openstack_vpnaas_ipsec_policy_v2" "network" {
  name                 = var.name
  auth_algorithm       = "sha256"
  encryption_algorithm = "aes-256"
  pfs                  = "group14"
}

# Create VPN Service
resource "openstack_vpnaas_service_v2" "network" {
  depends_on     = [openstack_networking_router_interface_v2.network]
  name           = var.name
  router_id      = openstack_networking_router_v2.network.id
  admin_state_up = "true"
}

# Create VPN Endpoints
resource "openstack_vpnaas_endpoint_group_v2" "ep_subnet" {
  name      = "${var.name}-ep-subnet"
  type      = "subnet"
  endpoints = [openstack_networking_subnet_v2.network.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "openstack_vpnaas_endpoint_group_v2" "ep_cidr" {
  name      = "${var.name}-ep-cidr"
  type      = "cidr"
  endpoints = [var.remote_cidr]
  lifecycle {
    create_before_destroy = true
  }
}
