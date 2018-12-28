# IPsec IKEv1 PSK
variable "ipsec_psk" {
  type    = "string"
  default = "super_secret"
}

# Public key to access example instances
variable "public_key" {
  type    = "string"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLOH1KvssMlw6fMGO9XGfq+fiPjQkyBnXM5fVcBuHuAMRMxJNomdNpjps0gjypA3RNFgdoTi2fDSa7oG2k2fCLPCFbcXArOw7hgffHXaGlZmJzOxL8TtZrkwKo4z1UEunmaJ5gHAXTrl8KH+dmq0mrZYsit0SIouast5FDDF6kCASzgxr0Jz4gfwKBH03tBvDiSSpmMg1VgF6EFJwtGYk6JHt0lgYbj9RkBDhl3zyDL67YZuBfuCR5JXpAOKjXEtTZdfezFIqhH/iCCreDPct4I78p0sRUaduSmh/hL0UJ4tC2NoDuMfoIXJqwsFSRcgslh/UmQEY2TgoFcjKvS69Z"
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
  public_key = "${var.public_key}"
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
  public_key = "${var.public_key}"
}

# VPN Site-to-Site connections
resource "openstack_vpnaas_site_connection_v2" "cbk_to_dbl" {
  name           = "CBK to DBL"
  provider       = "openstack.cbk"
  vpnservice_id  = "${module.network_cbk.vpnservice_id}"
  ikepolicy_id   = "${module.network_cbk.ikepolicy_id}"
  ipsecpolicy_id = "${module.network_cbk.ipsecpolicy_id}"
  peer_id        = "${module.network_dbl.peer_id}"
  peer_address   = "${module.network_dbl.peer_id}"
  psk            = "${var.ipsec_psk}"
  peer_cidrs     = ["${module.network_dbl.cidr}"]
  admin_state_up = "true"
}

resource "openstack_vpnaas_site_connection_v2" "dbl_to_cbk" {
  name           = "DBL to CBK"
  provider       = "openstack.dbl"
  vpnservice_id  = "${module.network_dbl.vpnservice_id}"
  ikepolicy_id   = "${module.network_dbl.ikepolicy_id}"
  ipsecpolicy_id = "${module.network_dbl.ipsecpolicy_id}"
  peer_id        = "${module.network_cbk.peer_id}"
  peer_address   = "${module.network_cbk.peer_id}"
  psk            = "${var.ipsec_psk}"
  peer_cidrs     = ["${module.network_cbk.cidr}"]
  admin_state_up = "true"
}
