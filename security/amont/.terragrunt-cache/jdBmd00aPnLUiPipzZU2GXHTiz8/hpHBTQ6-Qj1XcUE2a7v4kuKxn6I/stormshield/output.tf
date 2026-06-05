output "private_key_pem" {
  value     = tls_private_key.instance_key.private_key_pem
  sensitive = true
}

output "instance_id" {
  value = openstack_compute_instance_v2.fw.id
}
