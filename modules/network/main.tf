terraform {
  required_providers {
    ovh       = { source = "ovh/ovh" }
    openstack = { source = "terraform-provider-openstack/openstack" }
  }
}

# 1. Création du réseau privé via OVH
resource "ovh_cloud_project_network_private" "vlan" {
  for_each     = var.vlans
  service_name = var.service_name
  name         = each.value.name
  vlan_id      = each.value.vlan_id
  regions      = [var.region]
}

# 2. Création du Subnet via OpenStack
resource "openstack_networking_subnet_v2" "subnet" {
  for_each   = var.vlans
  region     = var.region
  network_id = tolist(ovh_cloud_project_network_private.vlan[each.key].regions_attributes)[0].openstackid
  cidr       = each.value.cidr
  name       = each.value.name

  # --- LOGIQUE GATEWAY DYNAMIQUE ---
  # On ne définit gateway_ip QUE si elle existe dans var.vlans
  gateway_ip = each.value.gateway_ip != null ? each.value.gateway_ip : null
  
  # On ne définit no_gateway QUE si gateway_ip est absent (null)
  # Pour éviter le conflit, on utilise null si une IP est présente
  no_gateway = each.value.gateway_ip == null ? true : null

  # --- LOGIQUE DHCP ---
  enable_dhcp = each.value.enable_dhcp
  dns_nameservers = each.value.enable_dhcp ? ["213.186.33.99", "8.8.8.8"] : []

  allocation_pool {
    start = each.value.start
    end   = each.value.end
  }
}
