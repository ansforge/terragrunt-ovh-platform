variable "service_name" { type = string }
variable "region" { type = string }

variable "vlans" {
  type = map(object({
    name        = string
    vlan_id     = number
    cidr        = string
    start       = string
    end         = string
    enable_dhcp = optional(bool, false)
    gateway_ip  = optional(string, null)
  }))
}
