variable "external_network" {
  type        = string
  description = "external network name"
  default     = "ext-net"
}

variable "ssh_publickey" {
  type        = string
  description = "ssh-rsa public key in authorized_keys format (ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host)"
}

data "openstack_networking_network_v2" "ext-net" {
  name = var.external_network
}

