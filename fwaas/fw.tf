resource "openstack_fw_rule_v2" "allow_to_http" {
  name             = "allow_to_http"
  description      = "allow destination HTTP"
  action           = "allow"
  protocol         = "tcp"
  destination_port = "80"
  enabled          = "true"
}

resource "openstack_fw_rule_v2" "allow_from_http" {
  name        = "allow_from_http"
  description = "allow source HTTP"
  action      = "allow"
  protocol    = "tcp"
  source_port = "80"
  enabled     = "true"
}

resource "openstack_fw_rule_v2" "allow_to_https" {
  name             = "allow_to_http"
  description      = "allow destination HTTP"
  action           = "allow"
  protocol         = "tcp"
  destination_port = "443"
  enabled          = "true"
}

resource "openstack_fw_rule_v2" "allow_from_https" {
  name        = "allow_from_https"
  description = "allow source HTTPS"
  action      = "allow"
  protocol    = "tcp"
  source_port = "443"
  enabled     = "true"
}

resource "openstack_fw_rule_v2" "allow_to_ssh" {
  name             = "allow_to_ssh"
  description      = "allow destination SSH"
  action           = "allow"
  protocol         = "tcp"
  destination_port = "22"
  enabled          = "true"
}

resource "openstack_fw_rule_v2" "allow_from_ssh" {
  name        = "allow_from_ssh"
  description = "allow source SSH"
  action      = "allow"
  protocol    = "tcp"
  source_port = "22"
  enabled     = "true"
}

resource "openstack_fw_rule_v2" "allow_to_dns" {
  name             = "allow_to_dns"
  description      = "allow destination DNS"
  action           = "allow"
  protocol         = "udp"
  destination_port = "53"
  enabled          = "true"
}

resource "openstack_fw_rule_v2" "allow_from_dns" {
  name        = "allow_from_dns"
  description = "allow source DNS"
  action      = "allow"
  protocol    = "udp"
  source_port = "53"
  enabled     = "true"
}

resource "openstack_fw_rule_v2" "deny" {
  name        = "deny"
  description = "deny everything"
  action      = "deny"
  protocol    = "any"
  enabled     = "true"
}

resource "openstack_fw_policy_v2" "ingress" {
  name = "ingress_policy"

  rules = [
    openstack_fw_rule_v2.allow_to_http.id,
    openstack_fw_rule_v2.allow_to_ssh.id,
    openstack_fw_rule_v2.allow_from_dns.id,
    openstack_fw_rule_v2.allow_from_http.id,
    openstack_fw_rule_v2.allow_from_https.id,
    openstack_fw_rule_v2.deny.id,
  ]
}

resource "openstack_fw_policy_v2" "egress" {
  name = "egress_policy"

  rules = [
    openstack_fw_rule_v2.allow_from_http.id,
    openstack_fw_rule_v2.allow_from_ssh.id,
    openstack_fw_rule_v2.allow_to_dns.id,
    openstack_fw_rule_v2.allow_to_http.id,
    openstack_fw_rule_v2.allow_to_https.id,
    openstack_fw_rule_v2.deny.id,
  ]
}

resource "openstack_fw_group_v2" "group_1" {
  name                       = "firewall_group"
  ingress_firewall_policy_id = openstack_fw_policy_v2.ingress.id
  egress_firewall_policy_id  = openstack_fw_policy_v2.egress.id
  ports                      = [openstack_networking_router_interface_v2.routerint_1.id]
}
