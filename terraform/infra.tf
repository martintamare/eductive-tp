# Une clef SSH par région
resource "openstack_compute_keypair_v2" "keypair_gra11" {
  provider   = openstack.ovh
  name       = "sshkey_${var.student_id}"
  public_key = file("~/.ssh/id_rsa.pub")
  region     = "GRA11"
}
resource "openstack_compute_keypair_v2" "keypair_sbg5" {
  provider   = openstack.ovh
  name       = "sshkey_${var.student_id}"
  public_key = file("~/.ssh/id_rsa.pub")
  region     = "SBG5"
}

# Front instance à GRA11
resource "openstack_compute_instance_v2" "front" {
  name        = "front_${var.student_id}"
  provider    = openstack.ovh
  image_name  = "Debian 11"
  flavor_name = "s1-2"
  region      = "GRA11"
  key_pair    = openstack_compute_keypair_v2.keypair_gra11.name
  network {
    name      = "Ext-Net"
  }
}

# GRA11 backend instance(s)
resource "openstack_compute_instance_v2" "gra_backends" {
  count       = var.gra_backends
  name        = "backend_gra_${var.student_id}_${count.index+1}"
  provider    = openstack.ovh
  image_name  = "Debian 11"
  flavor_name = "s1-2"
  region      = "GRA11"
  key_pair    = openstack_compute_keypair_v2.keypair_gra11.name
  network {
    name      = "Ext-Net"
  }
}

# SBG5 backend instance(s)
resource "openstack_compute_instance_v2" "sbg_backends" {
  count       = var.sbg_backends
  name        = "backend_sbg_${var.student_id}_${count.index+1}"
  provider    = openstack.ovh
  image_name  = "Debian 11"
  flavor_name = "s1-2"
  region      = "SBG5"
  key_pair    = openstack_compute_keypair_v2.keypair_sbg5.name
  network {
    name      = "Ext-Net"
  }
}

# Inventaire
resource "local_file" "inventory" {
  filename = "../ansible/inventory.yml"
  content  = templatefile("templates/inventory.tmpl",
    {
      sbg_backends = [for k, p in openstack_compute_instance_v2.sbg_backends: p.access_ip_v4],
      gra_backends = [for k, p in openstack_compute_instance_v2.gra_backends: p.access_ip_v4],
      front = openstack_compute_instance_v2.front.access_ip_v4,
    }
  )
}
