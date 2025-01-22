variable "region" {
  type = string
}

variable "name" {
  type    = string
  default = "unicorn"
}

variable "image_name" {
  type        = string
  description = "Openstack image node"
  default     = null
}

variable "network" {
  type    = string
  default = "unicorn"
}

variable "network_id" {
  type    = string
}

variable "subnet_id" {
  type    = string
}

variable "public_key" {
  type = string
}

variable "flavor" {
  type = string
  default = "m2.tiny"
}

variable "app_depends_on" {
  type    = any
    default = null
}
