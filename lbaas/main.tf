resource "openstack_compute_keypair_v2" "kp_admin" {
  name       = "kp_admin"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzBd/ZXus0RGHqi6TdfLQcZML4b+woARlbV/+V9bsvdXKbe7FVLhd2oYV5n5kBI4DfEtD0J5BXBXbzG1BW9WmB/Ty2wlwUu+NFDCn+3kDTGov9Wlo5bfkPD/KDi/UNOqJvOMoCGzkCK04Di0ykG38gLKeOUDtLbh/s9Manr9vDguvtBV4UE7/kNQFzGFffB3ZyvKVzikrsm5Ri3knjCRwppN6BGZVMowTmhDgczyS3CJekdCBrgXu3eePuWbFnPVmSAapl775ouCLGAW0KsiSc9T4iTdpAMFxtvA5Pbciv4FDOfEf8w1t5xgko3KAPMLz37b7mqmRhQTwkW3BNaiZqLTC2RqZkHI5a6u655I1SJYZbJT2F/Ys8WaKTSdGLxRJ+rcV8YV0FveP6fa97gpqp6UmstGE7QsRaXPc9OG3U0hCTPYFlJ9QJ95FQMGQMt3/qsZHGWSI3H8jLn8Pqeky+XZA0Xq7cJq9n5gGpMVH2UgRT1WzbCAYiDMiNtzIxBXg5xVCzkhN98S7p+IxOpw6BsByOrIogo5lyC/qVS6tD5XCsAtOFk0ldhB/FuuyOrR1pSq3GZCyuiXkXWrwuSw7k5a7pkh3+E+t2pqYWgLFAaClNA0TI4UFfNnkgEfozop5UWuvNkbd98ruBHaGrQ0ASqWk4nEztHxUeJ/NkQ+n5uw== r.nurgaliyev@syseleven.de"
}

resource "openstack_compute_secgroup_v2" "sg_ssh" {
  name        = "sg_ssh"
  description = "Allow inboud SSH"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "sg_web" {
  name        = "sg_web"
  description = "Allow inboud HTTP"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "net_lbdemo" {
  name           = "net_lbdemo"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_lbdemo" {
  name            = "subnet_lbdemo"
  network_id      = "${openstack_networking_network_v2.net_lbdemo.id}"
  cidr            = "192.168.1.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  ip_version      = 4
}

resource "openstack_networking_router_v2" "router_lbdemo" {
  name                = "router_lbdemo"
  admin_state_up      = true
  external_network_id = "8bb661f5-76b9-45f1-9ef9-eeffcd025fe4"
}

resource "openstack_networking_router_interface_v2" "routerint_lbdemo" {
  router_id = "${openstack_networking_router_v2.router_lbdemo.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_lbdemo.id}"
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/assets/cloud.cfg")}"

  vars {
    init_app_sh = "${base64encode(file("${path.module}/assets/init-app.sh"))}"
  }
}

resource "openstack_compute_instance_v2" "instance_lbdemo" {
  count       = 3
  name        = "App Instance ${count.index+1}"
  image_id    = "32cfc6e3-abfc-4c92-8bf4-ce7191b6f74c"
  flavor_name = "m1.micro"
  key_pair    = "${openstack_compute_keypair_v2.kp_admin.name}"
  user_data   = "${data.template_file.cloud_config.rendered}"

  security_groups = [
    "default",
    "${openstack_compute_secgroup_v2.sg_web.name}",
  ]

  network {
    name = "${openstack_networking_network_v2.net_lbdemo.name}"
  }
}

resource "openstack_compute_instance_v2" "instance_jumphost" {
  name        = "Jumphost"
  image_id    = "32cfc6e3-abfc-4c92-8bf4-ce7191b6f74c"
  flavor_name = "m1.micro"
  key_pair    = "${openstack_compute_keypair_v2.kp_admin.name}"

  security_groups = [
    "default",
    "${openstack_compute_secgroup_v2.sg_ssh.name}",
  ]

  network {
    name = "${openstack_networking_network_v2.net_lbdemo.name}"
  }
}

resource "openstack_compute_floatingip_v2" "fip_lbdemo_jumphost" {
  pool = "ext-net"
}

resource "openstack_compute_floatingip_associate_v2" "fipas_lbdemo" {
  floating_ip = "${openstack_compute_floatingip_v2.fip_lbdemo_jumphost.address}"
  instance_id = "${openstack_compute_instance_v2.instance_jumphost.id}"
}

resource "openstack_lb_loadbalancer_v2" "lb_app" {
  vip_subnet_id = "${openstack_networking_subnet_v2.subnet_lbdemo.id}"
  name          = "application loadbalancer"
}

resource "openstack_lb_listener_v2" "lb_app_listener" {
  protocol        = "TCP"
  protocol_port   = 80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.lb_app.id}"
}

resource "openstack_lb_pool_v2" "lb_app_pool" {
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.lb_app_listener.id}"
}

resource "openstack_lb_member_v2" "lb_app_pool_members" {
  count         = "${openstack_compute_instance_v2.instance_lbdemo.count}"
  address       = "${element(openstack_compute_instance_v2.instance_lbdemo.*.access_ip_v4, count.index)}"
  protocol_port = 80
  pool_id       = "${openstack_lb_pool_v2.lb_app_pool.id}"
  name          = "${element(openstack_compute_instance_v2.instance_lbdemo.*.name, count.index)}"
  subnet_id     = "${openstack_networking_subnet_v2.subnet_lbdemo.id}"
}
