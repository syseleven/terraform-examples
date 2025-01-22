variable "region" {
  type = string
}

variable "name" {
  type    = string
  default = "unicorn"
}

variable "cidr" {
  type = string
}

variable "remote_cidr" {
  type = string
}
