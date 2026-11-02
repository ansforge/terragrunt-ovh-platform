output "instance_ids" {
  description = "IDs des instances OpenStack"
  value       = { for k, v in openstack_compute_instance_v2.vm : k => v.id }
}

output "instance_ips" {
  description = "Adresses IP fixées pour chaque interface de VM"
  value = {
    for key, port in openstack_networking_port_v2.vm_ports : key => port.all_fixed_ips[0]
  }
}

output "resolved_images" {
  description = "Image réellement utilisée par chaque VM"
  value       = local.vm_image_ids
}

output "private_keys" {
  description = "Clés privées SSH générées par Terraform pour chaque VM"
  value       = { for k, v in tls_private_key.vm_key : k => v.private_key_openssh }
  sensitive   = true
}

output "public_keys" {
  description = "Clés publiques SSH de chaque VM"
  value       = { for k, v in tls_private_key.vm_key : k => v.public_key_openssh }
}

output "extra_volumes" {
  description = "Volumes supplémentaires créés"
  value = {
    for k, v in openstack_blockstorage_volume_v3.extra_disk : k => {
      id   = v.id
      name = v.name
      size = v.size
    }
  }
}

output "vm_inventory" {
  description = "Inventaire par VM (réseaux avec IP/MAC/CIDR, volumes, tags) consommé par la pipeline de provisionnement Ansible"
  value = {
    for k, vm in openstack_compute_instance_v2.vm : k => {
      id         = vm.id
      name       = vm.name
      flavor_id  = var.vms[k].flavor_id
      image_id   = local.vm_image_ids[k]
      image_name = var.vms[k].image_name
      tags       = var.vms[k].tags
      networks = [
        for i, net in var.vms[k].networks : {
          name    = net.name
          primary = i == 0
          ip      = net.name == "Ext-Net" ? (i == 0 ? vm.access_ip_v4 : null) : openstack_networking_port_v2.vm_ports["${k}_${net.name}"].all_fixed_ips[0]
          mac     = net.name == "Ext-Net" ? null : openstack_networking_port_v2.vm_ports["${k}_${net.name}"].mac_address
          cidr    = net.name == "Ext-Net" ? null : data.openstack_networking_subnet_v2.subnets[net.name].cidr
          gateway = net.name == "Ext-Net" ? null : data.openstack_networking_subnet_v2.subnets[net.name].gateway_ip
        }
      ]
      volumes = [
        for dk, d in local.all_extra_disks : {
          key  = dk
          name = d.name
          size = d.size
          id   = openstack_blockstorage_volume_v3.extra_disk[dk].id
        } if d.vm_key == k
      ]
    }
  }
}
