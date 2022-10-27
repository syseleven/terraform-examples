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

resource "openstack_compute_keypair_v2" "kp_admin" {
  name       = "kp_admin"
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

resource "openstack_compute_instance_v2" "instance_lbdemo" {
  count       = 3
  name        = "App Instance ${count.index + 1}"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = "m1.small"
  key_pair    = openstack_compute_keypair_v2.kp_admin.name
  user_data   = templatefile("${path.module}/assets/cloud.cfg", { init_app_sh = base64encode(file("${path.module}/assets/init-app.sh")) })

  security_groups = [
    openstack_compute_secgroup_v2.sg_web.name, "default"
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
  flavor_name = "m1.small"
  key_pair    = openstack_compute_keypair_v2.kp_admin.name

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

resource "openstack_networking_floatingip_v2" "fip_lbdemo_jumphost" {
  pool = "ext-net"
}

resource "openstack_networking_floatingip_associate_v2" "fipas_lbdemo" {
  floating_ip = openstack_networking_floatingip_v2.fip_lbdemo_jumphost.address
  instance_id = openstack_compute_instance_v2.instance_jumphost.id
}

resource "openstack_lb_loadbalancer_v2" "lb_app" {
  vip_subnet_id = openstack_networking_subnet_v2.subnet_lbdemo.id
  name          = "application loadbalancer"

}

data "openstack_keymanager_container_v1" "tls" {
  name = "certificate"
}

resource "openstack_lb_listener_v2" "lb_app_listener_https" {
  protocol                  = "TERMINATED_HTTPS"
  protocol_port             = 443
  default_tls_container_ref = data.openstack_keymanager_container_v1.tls.container_ref
  loadbalancer_id           = openstack_lb_loadbalancer_v2.lb_app.id

  insert_headers = {
    X-Forwarded-For  = "true"
    X-Forwarded-Port = "true"
  }

}


resource "openstack_lb_listener_v2" "lb_app_listener_http" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_app.id
}

resource "openstack_lb_pool_v2" "lb_app_pool" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.lb_app_listener_https.id
}

resource "openstack_lb_monitor_v2" "lb_app_monitor" {
  pool_id     = openstack_lb_pool_v2.lb_app_pool.id
  type        = "HTTP"
  url_path    = "/"
  delay       = 20
  timeout     = 10
  max_retries = 2
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

resource "openstack_networking_floatingip_v2" "fip_lbdemo_lb" {
  pool = "ext-net"
}

resource "openstack_networking_floatingip_associate_v2" "fipas_lbdemo_lb" {
  floating_ip = openstack_networking_floatingip_v2.fip_lbdemo_lb.address
  port_id     = openstack_lb_loadbalancer_v2.lb_app.vip_port_id
}


resource "openstack_lb_l7policy_v2" "l7policy_1" {
  name         = "redirect_to_https"
  action       = "REDIRECT_TO_URL"
  description  = "Redirect to https"
  position     = 1
  listener_id  = openstack_lb_listener_v2.lb_app_listener_http.id
  redirect_url = "https://${openstack_networking_floatingip_v2.fip_lbdemo_lb.address}"
}

resource "openstack_lb_l7rule_v2" "l7rule_1" {
  l7policy_id  = openstack_lb_l7policy_v2.l7policy_1.id
  type         = "PATH"
  compare_type = "STARTS_WITH"
  value        = "/"
}


output "loadbalancer_https" {
  value = "https://${openstack_networking_floatingip_v2.fip_lbdemo_lb.address}"
}

