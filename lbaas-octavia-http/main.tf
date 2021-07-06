provider "openstack" {
  use_octavia = true
}

data "openstack_images_image_v2" "image" {
  most_recent = true

  visibility = "public"
  properties = {
    os_distro  = "ubuntu"
    os_version = "20.04"
  }
}

data "openstack_networking_network_v2" "ext-net" {
  name = "ext-net"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "keypair"
  public_key = var.ssh_publickey
}

resource "openstack_compute_secgroup_v2" "sg_ssh" {
  name        = "sg_ssh"
  description = "Allow inbound SSH"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "sg_web" {
  name        = "sg_web"
  description = "Allow inbound HTTP"

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

data "template_file" "cloud_config" {
  template = file("${path.module}/assets/cloud.cfg")

  vars = {
    init_app_sh = base64encode(file("${path.module}/assets/init-app.sh"))
  }
}

resource "openstack_compute_instance_v2" "instance_lbdemo" {
  count       = 3
  name        = "App Instance ${count.index + 1}"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = "m1.tiny"
  key_pair    = openstack_compute_keypair_v2.keypair.name
  user_data   = data.template_file.cloud_config.rendered

  security_groups = [
    "default",
    openstack_compute_secgroup_v2.sg_web.name,
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
  flavor_name = "m1.tiny"
  key_pair    = openstack_compute_keypair_v2.keypair.name

  security_groups = [
    "default",
    openstack_compute_secgroup_v2.sg_ssh.name,
  ]

  network {
    uuid = openstack_networking_network_v2.net_lbdemo.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_floatingip_v2" "fip_lbdemo_jumphost" {
  pool = "ext-net"
}

resource "openstack_compute_floatingip_associate_v2" "fipas_lbdemo" {
  floating_ip = openstack_compute_floatingip_v2.fip_lbdemo_jumphost.address
  instance_id = openstack_compute_instance_v2.instance_jumphost.id
}

resource "openstack_lb_loadbalancer_v2" "lb_app" {
  vip_subnet_id = openstack_networking_subnet_v2.subnet_lbdemo.id
  name          = "application loadbalancer"
}

resource "openstack_lb_listener_v2" "lb_app_listener" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_app.id
  insert_headers = {
    X-Forwarded-For  = "true"
    X-Forwarded-Port = "true"
  }
}

resource "openstack_lb_pool_v2" "lb_app_pool" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.lb_app_listener.id
}

resource "openstack_lb_member_v2" "lb_app_pool_members" {
  count = length(openstack_compute_instance_v2.instance_lbdemo)
  address = element(
    openstack_compute_instance_v2.instance_lbdemo.*.access_ip_v4,
    count.index,
  )
  protocol_port = 80
  pool_id       = openstack_lb_pool_v2.lb_app_pool.id
  name = element(
    openstack_compute_instance_v2.instance_lbdemo.*.name,
    count.index,
  )
  subnet_id = openstack_networking_subnet_v2.subnet_lbdemo.id
}

resource "openstack_lb_monitor_v2" "lb_app_monitor" {
  pool_id        = openstack_lb_pool_v2.lb_app_pool.id
  type           = "HTTP"
  delay          = 10
  timeout        = 5
  max_retries    = 2
  url_path       = "/"
  expected_codes = 200
}

resource "openstack_networking_floatingip_v2" "fip_lbdemo_lb" {
  pool = "ext-net"
}

resource "openstack_networking_floatingip_associate_v2" "fipas_lbdemo_lb" {
  floating_ip = openstack_networking_floatingip_v2.fip_lbdemo_lb.address
  port_id     = openstack_lb_loadbalancer_v2.lb_app.vip_port_id
}

output "loadbalancer_http" {
  value = "http://${openstack_networking_floatingip_v2.fip_lbdemo_lb.address}"
}
