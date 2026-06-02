# modules/security/main.tf
terraform {
  required_providers {
    openstack = { source = "terraform-provider-openstack/openstack" }
    tls       = { source = "hashicorp/tls" }
  }
}

resource "tls_private_key" "instance_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "instance_kp" {
  name       = "key-${var.name}"
  public_key = tls_private_key.instance_key.public_key_openssh
}

# 1. Utilisation de data source pour trouver l'ID du réseau par son NOM
data "openstack_networking_network_v2" "networks" {
  for_each = { for n in var.networks : n.name => n if n.enabled }
  name     = each.key
  region   = var.region
}

# 2. Création du Port (Interface)
resource "openstack_networking_port_v2" "ports" {
  for_each   = { for n in var.networks : n.name => n if n.enabled }
  name       = "port-${var.name}-${each.key}"
  network_id = data.openstack_networking_network_v2.networks[each.key].id
  region     = var.region

  fixed_ip {
    ip_address = each.value.ip
  }

  port_security_enabled = false # Obligatoire pour Stormshield
}

# 3. L'Instance
resource "openstack_compute_instance_v2" "fw" {
  name      = var.name
  flavor_id = var.flavor
  image_id  = var.image
  key_pair  = openstack_compute_keypair_v2.instance_kp.name
  region    = var.region

  # Injection des ports pour résoudre l'erreur 409 (Multiple possible networks)
  dynamic "network" {
    for_each = openstack_networking_port_v2.ports
    content {
      port = network.value.id
    }
  }

  metadata = var.tags
}
