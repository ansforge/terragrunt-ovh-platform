include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "module" {
  path = "${get_parent_terragrunt_dir()}/module.hcl"
}

locals {
  common      = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env         = "prod"
  env_config  = local.common.locals.environments[local.env]
  module_conf = read_terragrunt_config("${get_parent_terragrunt_dir()}/module.hcl")
}

terraform {
  source = local.module_conf.locals.module_source
}

# Génération du provider OVH + Vault dynamique
generate "providers" {
  path      = "_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-PROVIDERS
    data "vault_generic_secret" "ovh_auth" {
      path = "${local.env_config.vault_mount}/ovh_key"
    }

    provider "ovh" {
      endpoint           = "ovh-eu"
      application_key    = data.vault_generic_secret.ovh_auth.data["OVH_APPLICATION_KEY"]
      application_secret = data.vault_generic_secret.ovh_auth.data["OVH_APPLICATION_SECRET"]
      consumer_key       = data.vault_generic_secret.ovh_auth.data["OVH_CONSUMER_KEY"]
    }
  PROVIDERS
}

inputs = {
  service_name = local.env_config.ovh_project_id
  bucket_name  = "infra-prod-sto-object-tf01"
}
