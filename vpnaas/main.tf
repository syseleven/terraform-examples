# Provider configuration

provider "openstack" {
  region = "dus2"
  alias  = "dus2"
}

provider "openstack" {
  region = "ham1"
  alias  = "ham1"
}

# IPsec IKEv1 PSK
variable "ipsec_psk" {
  type    = string
  default = "super_secret"
}

# Public key to access instances
variable "public_key" {
  type    = string
  description = "ssh-rsa public key in authorized_keys format (ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host)"
  # default = "ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host"
}

# Deploy infrastructure to ham1
module "network_ham1" {
  source      = "./modules/network"
  region      = "ham1"
  cidr        = "10.100.1.0/24"
  remote_cidr = "10.100.2.0/24"
}

module "application_ham1" {
  source         = "./modules/application"
  app_depends_on = [module.network_ham1.subnet]
  region         = "ham1"
  public_key     = var.public_key
  network_id     = module.network_ham1.network_id
  subnet_id      = module.network_ham1.subnet_id
}

# Deploy infrastructure to dus2
module "network_dus2" {
  source      = "./modules/network"
  region      = "dus2"
  cidr        = "10.100.2.0/24"
  remote_cidr = "10.100.1.0/24"
}

module "application_dus2" {
  source         = "./modules/application"
  app_depends_on = [module.network_dus2.subnet]
  region         = "dus2"
  public_key     = var.public_key
  network_id     = module.network_dus2.network_id
  subnet_id      = module.network_dus2.subnet_id
}

# VPN Site-to-Site connections
resource "openstack_vpnaas_site_connection_v2" "ham1_to_dus2" {
  name              = "ham1 to dus2"
  provider          = openstack.ham1
  vpnservice_id     = module.network_ham1.vpnservice_id
  ikepolicy_id      = module.network_ham1.ikepolicy_id
  ipsecpolicy_id    = module.network_ham1.ipsecpolicy_id
  peer_id           = module.network_dus2.peer_id
  peer_address      = module.network_dus2.peer_id
  psk               = var.ipsec_psk
  local_ep_group_id = module.network_ham1.ep_subnet_endpoint_group_id
  peer_ep_group_id  = module.network_ham1.ep_cidr_endpoint_group_id
  admin_state_up = "true"
}

resource "openstack_vpnaas_site_connection_v2" "dus2_to_ham1" {
  name              = "dus2 to ham1"
  provider          = openstack.dus2
  vpnservice_id     = module.network_dus2.vpnservice_id
  ikepolicy_id      = module.network_dus2.ikepolicy_id
  ipsecpolicy_id    = module.network_dus2.ipsecpolicy_id
  peer_id           = module.network_ham1.peer_id
  peer_address      = module.network_ham1.peer_id
  psk               = var.ipsec_psk
  local_ep_group_id = module.network_dus2.ep_subnet_endpoint_group_id
  peer_ep_group_id  = module.network_dus2.ep_cidr_endpoint_group_id
  admin_state_up = "true"
}
