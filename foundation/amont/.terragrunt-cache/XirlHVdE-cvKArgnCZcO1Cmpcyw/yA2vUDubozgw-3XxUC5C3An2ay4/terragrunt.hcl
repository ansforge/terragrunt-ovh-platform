include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "amont"
  env_config = local.common.locals.environments[local.env]
}

terraform {
  source = "${get_repo_root()}/modules/foundation"
}

dependencies {
  paths = ["../../network/amont", "../../security/amont"]
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
      name          = "infra-amont-tfansible01"
      flavor_id     = "acb62e0d-fa78-4a09-8e08-ba2e30fb4ff9"
      image_id      = "09189822-26b4-4407-87c3-2b2957588d53"
      key_name      = "vm-tfansible-key"
      extra_disk_gb = 0
      networks = [
        { name = "Ext-Net", ip = "", enabled = true },
        { name = "preprod-amont-infra-app-10.12.90.0-24", ip = "10.12.90.14", enabled = true }
      ]
      tags = { Owner = "infra-team", Env = "amont", App = "ansible" }
    }
    proxy = {
      name          = "infra-amont-proxy01"
      flavor_id     = "acb62e0d-fa78-4a09-8e08-ba2e30fb4ff9"
      image_id      = "09189822-26b4-4407-87c3-2b2957588d53"
      key_name      = "vm-proxy-key"
      extra_disk_gb = 50
      networks = [
        { name = "preprod-amont-dmz-exposed-10.12.30.0-24", ip = "10.12.30.11", enabled = true },
        { name = "preprod-amont-dmz-transit-10.12.70.0-24", ip = "10.12.70.11", enabled = true },
        { name = "preprod-amont-dmz-admin-10.12.52.0-24", ip = "10.12.52.11", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "amont", App = "proxy" }
    }
    repo = {
      name          = "infra-amont-repo01"
      flavor_id     = "acb62e0d-fa78-4a09-8e08-ba2e30fb4ff9"
      image_id      = "09189822-26b4-4407-87c3-2b2957588d53"
      key_name      = "vm-repo-key"
      extra_disk_gb = 150
      networks      = [{ name = "preprod-amont-infra-app-10.12.90.0-24", ip = "10.12.90.12", enabled = true }]
      tags          = { Owner = "infra-team", Env = "amont", App = "repo" }
    }
    freeipa = {
      name          = "infra-amont-freeipa01"
      flavor_id     = "acb62e0d-fa78-4a09-8e08-ba2e30fb4ff9"
      image_id      = "09189822-26b4-4407-87c3-2b2957588d53"
      key_name      = "vm-freeipa-key"
      extra_disk_gb = 0
      networks      = [{ name = "preprod-amont-infra-app-10.12.90.0-24", ip = "10.12.90.13", enabled = true }]
      tags          = { Owner = "infra-team", Env = "amont", App = "freeipa" }
    }
  }
}
