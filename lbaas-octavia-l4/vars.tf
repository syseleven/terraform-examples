variable "ssh_publickey" {
  type        = string
  description = "ssh-rsa public key in authorized_keys format (ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user@host)"
}

variable "lb_flavor_name" {
  type        = string
  description = "Name of the load balancer flavor to use"
  default     = "standard-l4"
}
