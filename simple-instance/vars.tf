variable "external_network" {
  type        = "string"
  description = "external network id for router"
}

variable "base_image" {
  type        = "string"
  description = "base image id"
}

variable "ssh_publickey" {
  type        = "string"
  description = "ssh-rsa public key in authorized_keys format (ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host)"

  # default = "ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host"
}
