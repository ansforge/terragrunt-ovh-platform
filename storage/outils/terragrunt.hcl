include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "outils"
  env_config = local.common.locals.environments[local.env]
}

terraform {
  source = "${get_repo_root()}/modules/storage"
}

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
  bucket_name  = "infra-outils-sto-object-tf01"
  region_name  = "EU-WEST-PAR"
}
