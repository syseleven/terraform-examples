resource "openstack_compute_keypair_v2" "kp_adminuser" {
  name       = "kp_adminuser"
  public_key = "ssh-rsa AAAAB [...] gvTnAz user@host"
}
