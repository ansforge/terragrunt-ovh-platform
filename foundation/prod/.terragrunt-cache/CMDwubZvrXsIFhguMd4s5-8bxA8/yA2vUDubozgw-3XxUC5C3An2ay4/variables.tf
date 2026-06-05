variable "region" {
  type        = string
  description = "Région OpenStack pour le déploiement"
}

variable "ovh_project_id" {
  type        = string
  description = "ID du projet OVH (nécessaire si des ressources OVH spécifiques sont ajoutées)"
}

variable "vms" {
  description = "Configuration des VMs transmise par la racine"
  type = map(object({
    name          = string
    flavor_id     = string
    image_id      = string
    key_name      = string
    extra_disk_gb = optional(number, 0)
    networks      = list(object({
      name    = string
      ip      = string
      enabled = bool
    }))
    tags = map(string)
  }))
}
