# modules/security/variables.tf

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "flavor" {
  type = string
}

variable "image" {
  type = string
}

# On retire "key_pair" car on génère la clé SSH dynamiquement dans le module maintenant
# variable "key_pair" { type = string } 

variable "tags" {
  type = map(string)
}

variable "networks" {
  description = "Liste des réseaux avec ip et enabled"
  type = list(object({
    name    = string
    ip      = string
    enabled = bool
  }))
}
