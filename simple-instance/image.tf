data "openstack_images_image_v2" "image" {
  most_recent = true
  properties {
    os_distro = "ubuntu"
    os_version = "16.04"
  }
}
