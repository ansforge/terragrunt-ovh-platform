include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "prod"
  env_config = local.common.locals.environments[local.env]
  module_conf = read_terragrunt_config("${get_terragrunt_dir()}/../module.hcl")
}

terraform {
  source = local.module_conf.locals.module_source
}

dependencies {
  paths = ["../../network/prod", "../../security/prod"]
}

generate "providers" {
  path      = "_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-PROVIDERS
    ephemeral "vault_kv_secret_v2" "os" {
      mount = "${local.env_config.vault_mount}"
      name  = "openstack_key"
    }

    locals {
      os_creds = ephemeral.vault_kv_secret_v2.os.data
    }

    provider "openstack" {
      auth_url                      = local.os_creds["OS_AUTH_URL"]
      application_credential_id     = local.os_creds["OS_APPLICATION_CREDENTIAL_ID"]
      application_credential_secret = local.os_creds["OS_APPLICATION_CREDENTIAL_SECRET"]
      region                        = "${local.env_config.region}"
    }
  PROVIDERS
}

inputs = {
  region         = local.env_config.region
  ovh_project_id = local.env_config.ovh_project_id

  vms = {
    tfansible = {
      name          = "infra-prod-tfansible01"
      flavor_id     = "94d7bb57-156a-4e7d-8840-1e9e4bcbe304"
      image_id      = "587c721d-e39f-4061-8e42-059104b88f21"
      key_name      = "vm-tfansible-key"
      extra_disk_gb = 0
      networks = [
        { name = "Ext-Net", ip = "", enabled = true },
        { name = "prod-production-infra-app-10.11.90.0-24", ip = "10.11.90.14", enabled = true }
      ]
      tags = { Owner = "infra-team", Env = "prod", App = "ansible" }
    }

    proxy = {
      name          = "infra-prod-proxy01"
      flavor_id     = "94d7bb57-156a-4e7d-8840-1e9e4bcbe304"
      image_id      = "587c721d-e39f-4061-8e42-059104b88f21"
      key_name      = "vm-proxy-key"
      extra_disk_gb = 50
      networks = [
        { name = "prod-production-dmz-exposed-10.11.30.0-24", ip = "10.11.30.11", enabled = true },
        { name = "prod-production-dmz-transit-10.11.70.0-24", ip = "10.11.70.11", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "prod", App = "squid" }
    }

    repo = {
      name          = "infra-prod-repo01"
      flavor_id     = "94d7bb57-156a-4e7d-8840-1e9e4bcbe304"
      image_id      = "587c721d-e39f-4061-8e42-059104b88f21"
      key_name      = "vm-repo-key"
      extra_disk_gb = 150
      networks      = [{ name = "prod-production-infra-app-10.11.90.0-24", ip = "10.11.90.12", enabled = true }]
      tags          = { Owner = "infra-team", Env = "prod", App = "repo" }
    }

    freeipa = {
      name          = "infra-prod-freeipa01"
      flavor_id     = "94d7bb57-156a-4e7d-8840-1e9e4bcbe304"
      image_id      = "587c721d-e39f-4061-8e42-059104b88f21"
      key_name      = "vm-freeipa-key"
      extra_disk_gb = 0
      networks      = [{ name = "prod-production-infra-app-10.11.90.0-24", ip = "10.11.90.13", enabled = true }]
      tags          = { Owner = "infra-team", Env = "prod", App = "freeipa" }
    }
  }
}
