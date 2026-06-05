include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "outils"
  env_config = local.common.locals.environments[local.env]
}

terraform {
  source = "${get_repo_root()}/modules/foundation"
}

dependencies {
  paths = ["../../network/outils", "../../security/outils"]
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
      name          = "infra-outils-tfansible01"
      flavor_id     = "1d6ae309-12da-4011-9169-56e4a3159e5e"
      image_id      = "4db92e15-38a0-4e25-8290-549bb81e34e5"
      key_name      = "vm-tfansible-key"
      extra_disk_gb = 0
      networks = [
        { name = "Ext-Net", ip = "", enabled = true },
        { name = "outils-infra-app-10.16.90.0-24", ip = "10.16.90.14", enabled = true }
      ]
      tags = { Owner = "infra-team", Env = "outils", App = "ansible" }
    }
    proxy = {
      name          = "infra-outils-proxy01"
      flavor_id     = "1d6ae309-12da-4011-9169-56e4a3159e5e"
      image_id      = "4db92e15-38a0-4e25-8290-549bb81e34e5"
      key_name      = "vm-proxy-key"
      extra_disk_gb = 50
      networks = [
        { name = "outils-dmz-exposed-10.15.30.0-24", ip = "10.15.30.11", enabled = true },
        { name = "outils-dmz-transit-10.16.70.0-24", ip = "10.16.70.11", enabled = true },
        { name = "outils-dmz-admin-10.16.52.0-24", ip = "10.16.52.11", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "outils", App = "proxy" }
    }
    repo = {
      name          = "infra-outils-repo01"
      flavor_id     = "1d6ae309-12da-4011-9169-56e4a3159e5e"
      image_id      = "4db92e15-38a0-4e25-8290-549bb81e34e5"
      key_name      = "vm-repo-key"
      extra_disk_gb = 150
      networks      = [{ name = "outils-infra-app-10.16.90.0-24", ip = "10.16.90.12", enabled = true }]
      tags          = { Owner = "infra-team", Env = "outils", App = "repo" }
    }
    freeipa = {
      name          = "infra-outils-freeipa01"
      flavor_id     = "1d6ae309-12da-4011-9169-56e4a3159e5e"
      image_id      = "4db92e15-38a0-4e25-8290-549bb81e34e5"
      key_name      = "vm-freeipa-key"
      extra_disk_gb = 0
      networks      = [{ name = "outils-infra-app-10.16.90.0-24", ip = "10.16.90.13", enabled = true }]
      tags          = { Owner = "infra-team", Env = "outils", App = "freeipa" }
    }
  }
}
