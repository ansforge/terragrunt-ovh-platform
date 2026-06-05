variable "name" { type = string }
variable "flavor" { type = string }
variable "image" { type = string }
variable "region" { type = string }
variable "networks" {
  type = list(object({
    name    = string
    ip      = string
    enabled = bool
  }))
}
variable "tags" {
  type    = map(string)
  default = {}
}
