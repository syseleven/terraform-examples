data "openstack_networking_network_v2" "nfs_net" {
  name = "nfs-net"
}

resource "openstack_networking_port_v2" "nfs_port_blue" {
  name           = "nfs_port_blue"
  network_id     = data.openstack_networking_network_v2.nfs_net.id
  admin_state_up = "true"
}


resource "openstack_networking_port_v2" "nfs_port_red" {
  name           = "nfs_port_red"
  network_id     = data.openstack_networking_network_v2.nfs_net.id
  admin_state_up = "true"
}

resource "openstack_sharedfilesystem_share_v2" "share_1" {
  name             = "nfs_share"
  description      = "test share description"
  share_proto      = "NFS"
  size             = 1
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access_red" {
  share_id     = openstack_sharedfilesystem_share_v2.share_1.id
  access_type  = "ip"
  access_to    = openstack_compute_instance_v2.instance_red.network.1.fixed_ip_v4
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access_blue" {
  share_id     = openstack_sharedfilesystem_share_v2.share_1.id
  access_type  = "ip"
  access_to    = openstack_compute_instance_v2.instance_blue.network.1.fixed_ip_v4
  access_level = "rw"
}

data "openstack_sharedfilesystem_share_v2" "share_1" {
  depends_on = [openstack_sharedfilesystem_share_v2.share_1]
  name = "nfs_share"
  status = "available"
}

resource "null_resource" "wait_for_share_instance" {
  depends_on = [
    openstack_compute_instance_v2.instance_blue,
    openstack_compute_instance_v2.instance_red,
    data.openstack_sharedfilesystem_share_v2.share_1
  ]

  provisioner "local-exec" {
    command = "sleep 60"  # Adjust this delay as needed to ensure the share is ready
  }
}

resource "null_resource" "mount_share" {
  depends_on = [null_resource.wait_for_share_instance]

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -l ubuntu ${openstack_networking_floatingip_v2.fip_blue.address} 'sudo apt update; sudo apt install -y nfs-common'"
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -l ubuntu ${openstack_networking_floatingip_v2.fip_blue.address} 'sudo mount.nfs4 ${data.openstack_sharedfilesystem_share_v2.share_1.export_locations.0.path} /mnt/'"
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -l ubuntu ${openstack_networking_floatingip_v2.fip_blue.address} 'sudo dd if=/dev/zero of=/mnt/hello-world.txt bs=1M count=512'"
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -l ubuntu ${openstack_networking_floatingip_v2.fip_red.address} 'sudo apt update; sudo apt install -y nfs-common'"
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -l ubuntu ${openstack_networking_floatingip_v2.fip_red.address} 'sudo mount.nfs4 ${data.openstack_sharedfilesystem_share_v2.share_1.export_locations.0.path} /mnt/'"
  }
}

output "ls_instance_blue" {
  value = "ssh -l ubuntu ${openstack_networking_floatingip_v2.fip_blue.address} 'ls -lah /mnt/'"
}
output "ls_instance_red" {
  value = "ssh -l ubuntu ${openstack_networking_floatingip_v2.fip_red.address} 'ls -lah /mnt/'"
}