data "openstack_images_image_v2" "image" {
  most_recent = true

  visibility = "public"
  properties = {
    os_distro  = "ubuntu"
    os_version = "24.04"
  }
}

data "openstack_networking_network_v2" "ext-net" {
  name = "ext-net"
}

resource "openstack_compute_keypair_v2" "kp_admin" {
  name       = "kp_admin"
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

resource "openstack_networking_network_v2" "net_1" {
  name           = "fwdemo"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name            = "fwdemo"
  network_id      = openstack_networking_network_v2.net_1.id
  cidr            = "192.168.1.0/24"
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
  ip_version      = 4
}

resource "openstack_networking_router_v2" "router_1" {
  name                = "fwdemo"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext-net.id
}

resource "openstack_networking_router_interface_v2" "routerint_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_compute_instance_v2" "instance_1" {
  name        = "fwdemo"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = var.flavor
  key_pair    = openstack_compute_keypair_v2.kp_admin.name
  user_data = templatefile("${path.module}/assets/cloud.cfg", {
    init_app_sh = base64encode(file("${path.module}/assets/init-app.sh"))
  })

  security_groups = [
    "default",
    openstack_networking_secgroup_v2.sg_web.name,
    openstack_networking_secgroup_v2.sg_ssh.name,
  ]

  network {
    uuid = openstack_networking_network_v2.net_1.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = "ext-net"
}

data "openstack_networking_port_v2" "port_instance_1" {
  device_id  = openstack_compute_instance_v2.instance_1.id
  network_id = openstack_compute_instance_v2.instance_1.network.0.uuid
}

resource "openstack_networking_floatingip_associate_v2" "fipas_1" {
  floating_ip = openstack_networking_floatingip_v2.fip_1.address
  port_id     = data.openstack_networking_port_v2.port_instance_1.id
}

