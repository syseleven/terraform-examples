variable "ssh_publickey" {
  type        = string
  description = "ssh-rsa public key in authorized_keys format (ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host)"
}

variable "flavor" {
  type        = string
  description = "Flavor for VM"
  default     = "m2.tiny"
}
