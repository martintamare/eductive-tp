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
  network {
    name        = ovh_cloud_project_network_private.network.name
    fixed_ip_v4 = "192.168.${var.vlan_id}.254"
  }
  depends_on    = [ovh_cloud_project_network_private_subnet.subnet_gra11]
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
  network {
    name        = ovh_cloud_project_network_private.network.name
    fixed_ip_v4 = "192.168.${var.vlan_id}.${count.index + 1}"
  }
  depends_on    = [ovh_cloud_project_network_private_subnet.subnet_gra11]
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
  network {
    name        = ovh_cloud_project_network_private.network.name
    fixed_ip_v4 = "192.168.${var.vlan_id}.${count.index + 101}"
  }
  depends_on    = [ovh_cloud_project_network_private_subnet.subnet_sbg5]
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

# Vrack Réseau
 resource "ovh_cloud_project_network_private" "network" {
    service_name = var.service_name
    name         = "private_network_${var.student_id}"
    regions      = ["GRA11", "SBG5"]
    provider     = ovh.ovh
    vlan_id      = var.vlan_id
}

# Vrack Subnet GRA11
resource "ovh_cloud_project_network_private_subnet" "subnet_gra11" {
    service_name = var.service_name
    network_id   = ovh_cloud_project_network_private.network.id
    start        = var.vlan_dhcp_start
    end          = var.vlan_dhcp_end
    network      = var.vlan_dhcp_network
    region       = "GRA11"
    provider     = ovh.ovh
    no_gateway   = true
}

# Vrack Subnet SBG5
resource "ovh_cloud_project_network_private_subnet" "subnet_sbg5" {
    service_name = var.service_name
    network_id   = ovh_cloud_project_network_private.network.id
    start        = var.vlan_dhcp_start
    end          = var.vlan_dhcp_end
    network      = var.vlan_dhcp_network
    region       = "SBG5"
    provider     = ovh.ovh
    no_gateway   = true
}
