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
