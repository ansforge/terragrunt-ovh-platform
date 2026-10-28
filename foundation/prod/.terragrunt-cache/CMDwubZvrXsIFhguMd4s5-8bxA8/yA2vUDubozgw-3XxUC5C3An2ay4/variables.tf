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
    name      = string
    flavor_id = string
    key_name  = string

    # Fournir SOIT image_id SOIT image_name (image_name prioritaire).
    # image_name évite de casser quand OVH purge un ancien ID d'image publique.
    image_id   = optional(string)
    image_name = optional(string)

    # Ancien mécanisme : un seul disque supplémentaire
    extra_disk_gb = optional(number, 0)

    # Nouveau mécanisme : N disques supplémentaires
    extra_disks = optional(list(object({
      name = optional(string)
      size = number
      type = optional(string) # classic | high-speed | high-speed-gen2
    })), [])

    networks = list(object({
      name    = string
      ip      = string
      enabled = bool
    }))

    tags = map(string)
  }))

  validation {
    condition     = alltrue([for k, v in var.vms : v.image_id != null || v.image_name != null])
    error_message = "Chaque VM doit définir image_id ou image_name."
  }
}
