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
  name           = "CBK to DBL"
  provider       = openstack.cbk
  vpnservice_id  = module.network_cbk.vpnservice_id
  ikepolicy_id   = module.network_cbk.ikepolicy_id
  ipsecpolicy_id = module.network_cbk.ipsecpolicy_id
  peer_id        = module.network_dbl.peer_id
  peer_address   = module.network_dbl.peer_id
  psk            = var.ipsec_psk
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  peer_cidrs     = [module.network_dbl.cidr]
  admin_state_up = "true"
}

resource "openstack_vpnaas_site_connection_v2" "dbl_to_cbk" {
  name           = "DBL to CBK"
  provider       = openstack.dbl
  vpnservice_id  = module.network_dbl.vpnservice_id
  ikepolicy_id   = module.network_dbl.ikepolicy_id
  ipsecpolicy_id = module.network_dbl.ipsecpolicy_id
  peer_id        = module.network_cbk.peer_id
  peer_address   = module.network_cbk.peer_id
  psk            = var.ipsec_psk
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  peer_cidrs     = [module.network_cbk.cidr]
  admin_state_up = "true"
}

