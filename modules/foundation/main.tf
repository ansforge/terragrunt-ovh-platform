terraform {
  required_providers {
    openstack = { source = "terraform-provider-openstack/openstack" }
    tls       = { source = "hashicorp/tls" }
  }
}

locals {
  # Disques historiques (extra_disk_gb) : clés inchangées => aucun volume existant détruit
  legacy_extra_disks = {
    for k, v in var.vms : k => {
      vm_key      = k
      size        = v.extra_disk_gb
      name        = "infra-prod-${k}-extra"
      volume_type = null
    } if v.extra_disk_gb > 0
  }

  # Disques multiples (extra_disks) : clés "<vm>_data<N>"
  additional_extra_disks = {
    for d in flatten([
      for k, v in var.vms : [
        for i, disk in v.extra_disks : {
          key         = "${k}_data${i + 1}"
          vm_key      = k
          size        = disk.size
          name        = disk.name != null ? disk.name : "infra-prod-${k}-data${i + 1}"
          volume_type = disk.type
        }
      ]
    ]) : d.key => d
  }

  all_extra_disks = merge(local.legacy_extra_disks, local.additional_extra_disks)

  # Image effective de chaque VM : résolue par nom si image_name est fourni
  vm_image_ids = {
    for k, v in var.vms : k => (
      v.image_name != null
      ? data.openstack_images_image_v2.by_name[v.image_name].id
      : v.image_id
    )
  }
}

data "openstack_images_image_v2" "by_name" {
  for_each = toset([for k, v in var.vms : v.image_name if v.image_name != null])

  name        = each.value
  most_recent = true
}

resource "tls_private_key" "vm_key" {
  for_each  = var.vms
  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    ignore_changes = all
  }
}

resource "openstack_compute_keypair_v2" "vm_kp" {
  for_each   = var.vms
  name       = "vm-${each.key}-key"
  public_key = tls_private_key.vm_key[each.key].public_key_openssh

  lifecycle {
    ignore_changes = all
  }
}

data "openstack_networking_network_v2" "networks" {
  for_each = toset(distinct(flatten([
    for vm in var.vms : [for net in vm.networks : net.name]
  ])))

  name = each.value
}

data "openstack_networking_subnet_v2" "subnets" {
  for_each   = { for k, v in data.openstack_networking_network_v2.networks : k => v if k != "Ext-Net" }
  network_id = each.value.id
}

resource "openstack_networking_port_v2" "vm_ports" {
  for_each = {
    for pair in flatten([
      for vm_key, vm_val in var.vms : [
        for net in vm_val.networks : {
          vm_key   = vm_key
          net_name = net.name
          ip       = net.ip
        }
      ]
    ]) : "${pair.vm_key}_${pair.net_name}" => pair if pair.net_name != "Ext-Net"
  }

  name                  = "port-${each.value.vm_key}-${each.value.net_name}"
  network_id            = data.openstack_networking_network_v2.networks[each.value.net_name].id
  admin_state_up        = true
  port_security_enabled = false

  dynamic "fixed_ip" {
    for_each = each.value.net_name != "Ext-Net" && each.value.ip != "" ? [1] : []
    content {
      ip_address = each.value.ip
      subnet_id  = data.openstack_networking_subnet_v2.subnets[each.value.net_name].id
    }
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

resource "openstack_compute_instance_v2" "vm" {
  for_each = var.vms

  name      = each.value.name
  image_id  = local.vm_image_ids[each.key]
  flavor_id = each.value.flavor_id
  key_pair  = openstack_compute_keypair_v2.vm_kp[each.key].name

  metadata = each.value.tags

  network {
    name = each.value.networks[0].name == "Ext-Net" ? "Ext-Net" : null
    port = each.value.networks[0].name != "Ext-Net" ? openstack_networking_port_v2.vm_ports["${each.key}_${each.value.networks[0].name}"].id : null
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      user_data,
      network,
      key_pair,
      image_id,
      flavor_id,
      metadata,
      security_groups
    ]
  }
}

resource "openstack_blockstorage_volume_v3" "extra_disk" {
  for_each = local.all_extra_disks

  name        = each.value.name
  size        = each.value.size
  volume_type = each.value.volume_type

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

resource "openstack_compute_volume_attach_v2" "attach_extra" {
  for_each = local.all_extra_disks

  instance_id = openstack_compute_instance_v2.vm[each.value.vm_key].id
  volume_id   = openstack_blockstorage_volume_v3.extra_disk[each.key].id

  lifecycle {
    ignore_changes = all
  }
}

resource "openstack_compute_interface_attach_v2" "ai" {
  for_each = {
    for pair in flatten([
      for vm_key, vm_val in var.vms : [
        for i, net in vm_val.networks : {
          vm_key = vm_key
          name   = net.name
          index  = i
        }
      ]
    ]) : "${pair.vm_key}_${pair.name}" => pair if pair.index > 0 && pair.name != "Ext-Net"
  }

  instance_id = openstack_compute_instance_v2.vm[each.value.vm_key].id
  port_id     = openstack_networking_port_v2.vm_ports["${each.value.vm_key}_${each.value.name}"].id

  lifecycle {
    ignore_changes = all
  }
}
