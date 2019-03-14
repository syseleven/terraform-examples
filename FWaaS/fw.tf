resource "openstack_fw_rule_v1" "rule_1" {
  name             = "my-rule-1"
  description      = "Allow ssh traffic"
  action           = "allow"
  protocol         = "tcp"
  destination_port = "22"
  enabled          = "true"
}

resource "openstack_fw_rule_v1" "rule_2" {
  name        = "my-rule-2"
  description = "Drop icmp"
  action      = "deny"
  protocol    = "icmp"
  enabled     = "true"
}

resource "openstack_fw_policy_v1" "policy_1" {
  name = "my-policy"

  rules = ["${openstack_fw_rule_v1.rule_1.id}",
    "${openstack_fw_rule_v1.rule_2.id}",
  ]
}

resource "openstack_fw_firewall_v1" "firewall_1" {
  name               = "my-firewall"
  policy_id          = "${openstack_fw_policy_v1.policy_1.id}"
  associated_routers = ["${openstack_networking_router_v2.router.id}"]
}
