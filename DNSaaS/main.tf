resource "openstack_dns_zone_v2" "example_zone" {
  name        = "example.com."
  email       = "email2@example.com"
  description = "a zone"
  ttl         = 6000
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "rs_example_com" {
  zone_id     = openstack_dns_zone_v2.example_zone.id
  name        = "rs.example.com."
  description = "An example record set"
  ttl         = 3000
  type        = "A"
  records     = ["10.0.0.1"]
}

