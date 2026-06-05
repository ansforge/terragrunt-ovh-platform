terraform {
  required_providers {
    openstack = { source = "terraform-provider-openstack/openstack", version = ">= 1.53.0" }
    tls       = { source = "hashicorp/tls" }
  }
}

variable "region" { type = string }
variable "firewalls" {
  type = map(object({
    name   = string
    flavor = string
    image  = string
    networks = list(object({
      name    = string
      ip      = string
      enabled = bool
    }))
    tags = map(string)
  }))
}

module "stormshield" {
  source   = "./stormshield"
  for_each = var.firewalls

  name     = each.value.name
  flavor   = each.value.flavor
  image    = each.value.image
  region   = var.region
  networks = each.value.networks
  tags     = each.value.tags
}

output "fw_instance_ids" {
  value = { for k, v in module.stormshield : k => v.instance_id }
}

output "fw_private_keys" {
  value     = { for k, v in module.stormshield : k => v.private_key_pem }
  sensitive = true
}
