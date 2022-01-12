# IPsec IKEv1 PSK
variable "ipsec_psk" {
  type    = string
  default = "super_secret"
}

# Public key to access example instances
variable "public_key" {
  type        = string
  description = "ssh-rsa public key in authorized_keys format (ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host)"
  # default = "ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host"
}

# Region configuration
provider "openstack" {
  region = "dbl"
  alias  = "dbl"
}

provider "openstack" {
  region = "cbk"
  alias  = "cbk"
}

# Deploy infrastructure to CBK
module "network_cbk" {
  source = "./modules/network"
  region = "cbk"
  cidr   = "10.100.1.0/24"
}

module "application_cbk" {
  source     = "./modules/simple-app"
  region     = "cbk"
  public_key = var.public_key
}

# Deploy infrastructure to DBL
module "network_dbl" {
  source = "./modules/network"
  region = "dbl"
  cidr   = "10.100.2.0/24"
}

module "application_dbl" {
  source     = "./modules/simple-app"
  region     = "dbl"
  public_key = var.public_key
}

# VPN Site-to-Site connections
resource "openstack_vpnaas_site_connection_v2" "cbk_to_dbl" {
  name              = "CBK to DBL"
  provider          = openstack.cbk
  vpnservice_id     = module.network_cbk.vpnservice_id
  ikepolicy_id      = module.network_cbk.ikepolicy_id
  ipsecpolicy_id    = module.network_cbk.ipsecpolicy_id
  peer_id           = module.network_dbl.peer_id
  peer_address      = module.network_dbl.peer_id
  psk               = var.ipsec_psk
  local_ep_group_id = module.network_cbk.local_endpoint_group_id
  peer_ep_group_id  = openstack_vpnaas_endpoint_group_v2.peer_dbl.id
  admin_state_up    = "true"
  dpd {
    action   = "hold"
    timeout  = 120
    interval = 30
  }
}

resource "openstack_vpnaas_endpoint_group_v2" "peer_dbl" {
  provider  = openstack.cbk
  name      = "DBL peer"
  type      = "cidr"
  endpoints = [module.network_dbl.cidr]
  lifecycle {
    create_before_destroy = true
  }
}

resource "openstack_vpnaas_site_connection_v2" "dbl_to_cbk" {
  name              = "DBL to CBK"
  provider          = openstack.dbl
  vpnservice_id     = module.network_dbl.vpnservice_id
  ikepolicy_id      = module.network_dbl.ikepolicy_id
  ipsecpolicy_id    = module.network_dbl.ipsecpolicy_id
  peer_id           = module.network_cbk.peer_id
  peer_address      = module.network_cbk.peer_id
  psk               = var.ipsec_psk
  local_ep_group_id = module.network_dbl.local_endpoint_group_id
  peer_ep_group_id  = openstack_vpnaas_endpoint_group_v2.peer_cbk.id
  admin_state_up    = "true"
  dpd {
    action   = "hold"
    timeout  = 120
    interval = 30
  }
}

resource "openstack_vpnaas_endpoint_group_v2" "peer_cbk" {
  provider  = openstack.dbl
  name      = "CBK peer"
  type      = "cidr"
  endpoints = [module.network_cbk.cidr]
  lifecycle {
    create_before_destroy = true
  }
}
