provider "openstack" {
}

data "openstack_images_image_v2" "image" {
  most_recent = true
  visibility  = "public"

  properties = {
    os_distro   = "ubuntu"
    os_version  = "24.04"
  }
}

data "openstack_networking_network_v2" "ext-net" {
  name = "ext-net"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "lb_keypair"
  public_key = var.ssh_publickey
}

resource "openstack_networking_secgroup_v2" "sg_ssh" {
  name        = "allow_ssh_and_icmp"
  description = "Allow inbound SSH/ICMP for IPv4 and IPv6"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_ssh.id
}

resource "openstack_networking_secgroup_v2" "sg_web" {
  name        = "sg_web"
  description = "Allow inbound HTTP"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_web.id
}

resource "openstack_networking_network_v2" "net_lbdemo" {
  name           = "net_lbdemo"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "subnet_lbdemo" {
  name            = "subnet_lbdemo"
  network_id      = openstack_networking_network_v2.net_lbdemo.id
  cidr            = "192.168.1.0/24"
  dns_nameservers = ["37.123.105.116", "37.123.105.117"]
  ip_version      = 4
}

resource "openstack_networking_router_v2" "router_lbdemo" {
  name                = "router_lbdemo"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext-net.id
}

resource "openstack_networking_router_interface_v2" "routerint_lbdemo" {
  router_id = openstack_networking_router_v2.router_lbdemo.id
  subnet_id = openstack_networking_subnet_v2.subnet_lbdemo.id
}

resource "openstack_compute_instance_v2" "instance_lbdemo" {
  count       = 3
  name        = "App Instance ${count.index + 1}"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = "m2.tiny"
  key_pair    = openstack_compute_keypair_v2.keypair.name

  user_data = templatefile("${path.module}/assets/cloud.cfg", {
    init_app_sh = base64encode(file("${path.module}/assets/init-app.sh"))
  })

  security_groups = [
    "default",
    openstack_networking_secgroup_v2.sg_web.name
  ]

  network {
    uuid = openstack_networking_network_v2.net_lbdemo.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_instance_v2" "instance_jumphost" {
  name        = "Jumphost"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = "m2.tiny"
  key_pair    = openstack_compute_keypair_v2.keypair.name

  security_groups = [
    "default",
    openstack_networking_secgroup_v2.sg_ssh.name,
  ]

  network {
    uuid = openstack_networking_network_v2.net_lbdemo.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_networking_floatingip_v2" "fip_lbdemo_jumphost" {
  pool = "ext-net"
}

data "openstack_networking_port_v2" "port_instance_1" {
  device_id  = openstack_compute_instance_v2.instance_jumphost.id
  network_id = openstack_compute_instance_v2.instance_jumphost.network.0.uuid
}

resource "openstack_networking_floatingip_associate_v2" "fipas_lbdemo" {
  floating_ip = openstack_networking_floatingip_v2.fip_lbdemo_jumphost.address
  port_id     = data.openstack_networking_port_v2.port_instance_1.id
}

data "openstack_lb_flavor_v2" "lb_flavor" {
  name = var.lb_flavor_name
}

resource "openstack_lb_loadbalancer_v2" "lb_app" {
  vip_subnet_id     = openstack_networking_subnet_v2.subnet_lbdemo.id
  name              = "application loadbalancer"
  flavor_id         = data.openstack_lb_flavor_v2.lb_flavor.flavor_id
}

resource "openstack_lb_listener_v2" "lb_app_listener" {
  protocol        = "TCP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_app.id

  connection_limit = 1000
}

resource "openstack_lb_pool_v2" "lb_app_pool" {
  protocol    = "TCP"
  lb_method   = "SOURCE_IP_PORT"
  listener_id = openstack_lb_listener_v2.lb_app_listener.id

}


resource "openstack_lb_member_v2" "lb_app_pool_members" {
  count     = length(openstack_compute_instance_v2.instance_lbdemo)
  address   = element(
    openstack_compute_instance_v2.instance_lbdemo.*.access_ip_v4,
    count.index
  )
  protocol_port = 80
  pool_id       = openstack_lb_pool_v2.lb_app_pool.id
  name          = element(
    openstack_compute_instance_v2.instance_lbdemo.*.name,
    count.index
  )
  subnet_id     = openstack_networking_subnet_v2.subnet_lbdemo.id
}

resource "openstack_lb_monitor_v2" "lb_app_monitor" {
  pool_id        = openstack_lb_pool_v2.lb_app_pool.id
  type           = "TCP"
  delay          = 10
  timeout        = 5
  max_retries    = 2
  # url_path       = "/"
  # expected_codes = "200"
}

resource "openstack_networking_floatingip_v2" "fip_lbdemo_lb" {
  pool = "ext-net"
  port_id = openstack_lb_loadbalancer_v2.lb_app.vip_port_id
}



output "loadbalancer_http" {
  value = "http://${openstack_networking_floatingip_v2.fip_lbdemo_lb.address}"
}
