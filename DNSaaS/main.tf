resource "random_pet" "unique_domain" {
  prefix = "tfex"
}

resource "openstack_dns_zone_v2" "example_zone" {
  name        = "${random_pet.unique_domain.id}.com."
  email       = "email@${random_pet.unique_domain.id}.com"
  description = "An example dns zone"
  ttl         = 6000
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "rs_example_com" {
  zone_id     = openstack_dns_zone_v2.example_zone.id
  name        = "rs.${openstack_dns_zone_v2.example_zone.name}"
  description = "An example dns record set"
  ttl         = 3000
  type        = "A"
  records     = ["10.0.0.1"]
}

resource "openstack_dns_recordset_v2" "lr_example_com" {
  zone_id     = openstack_dns_zone_v2.example_zone.id
  name        = "lr.${openstack_dns_zone_v2.example_zone.name}"
  description = "An example for long txt records, one with the maximum unquoted unsplit length of 255 characters and one with 256 characters, splitted and quoted appropriately"
  ttl         = 3000
  type        = "TXT"
  records = [
    "123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "\"123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd\" \"ef0\""
  ]
}

