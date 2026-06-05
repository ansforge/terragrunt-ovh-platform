# UUIDs OpenStack pour les subnets et réseaux
output "network_uuids" {
  value = { for k, v in ovh_cloud_project_network_private.vlan : k => tolist(v.regions_attributes)[0].openstackid }
}

# IDs des subnets OpenStack
output "subnet_ids" {
  value = { for k, v in openstack_networking_subnet_v2.subnet : k => v.id }
}

# IDs OVH (VLANs)
output "ovh_vlan_ids" {
  value = { for k, v in ovh_cloud_project_network_private.vlan : k => v.id }
}
