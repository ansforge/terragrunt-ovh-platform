include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "outils"
  env_config = local.common.locals.environments[local.env]
}

terraform {
  source = "${get_repo_root()}/modules/security-cluster-outils"
}

dependency "network" {
  config_path = "../../network/outils"
  mock_outputs = { network_ids = {} }
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
  region = local.env_config.region

  firewalls = {
    "fwfe01" = {
      name   = "infra-outils-fwfe01"
      flavor = "e4943d80-10a3-461c-a4a2-2d17ea114fb0"
      image  = "333bc0fd-7067-4997-ae74-97f609f8d1bc"
      networks = [
        { name = "outils-fwfe-admin-10.15.20.0-24", ip = "10.15.20.254", enabled = true },
        { name = "outils-dmz-exposed-10.15.30.0-24", ip = "10.15.30.254", enabled = true },
        { name = "outils-fw-interco-172.16.26.16-28", ip = "172.16.26.25", enabled = true },
        { name = "outils-fw-front-57.130.50.224-28", ip = "57.130.50.238", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "outils", Role = "firewall" }
    }
  }

  wallix = {
    "bastion01" = {
      name   = "infra-outils-bastion01"
      flavor = "e4943d80-10a3-461c-a4a2-2d17ea114fb0"
      image  = "0a4ac254-c85a-40f7-97b8-0b3fa108d7d1"
      networks = [
        { name = "outils-infra-admin-10.16.51.0-24", ip = "10.16.51.52", enabled = true },
        { name = "outils-bastion-in-10.16.92.0-24", ip = "10.16.92.52", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "outils", Role = "bastion" }
    }
    "bastion02" = {
      name   = "infra-outils-bastion02"
      flavor = "e4943d80-10a3-461c-a4a2-2d17ea114fb0"
      image  = "0a4ac254-c85a-40f7-97b8-0b3fa108d7d1"
      networks = [
        { name = "outils-infra-admin-10.16.51.0-24", ip = "10.16.51.53", enabled = true },
        { name = "outils-bastion-in-10.16.92.0-24", ip = "10.16.92.53", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "outils", Role = "bastion" }
    }
    "wabam01" = {
      name   = "infra-outils-wabam01"
      flavor = "e4943d80-10a3-461c-a4a2-2d17ea114fb0"
      image  = "e5c8d8ad-9379-44ec-a2cf-45a974ada50d"
      networks = [
        { name = "outils-infra-admin-10.16.51.0-24", ip = "10.16.51.51", enabled = true },
        { name = "outils-bastion-in-10.16.92.0-24", ip = "10.16.92.51", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "outils", Role = "access-manager" }
    }
    "opnsense01" = {
      name   = "infra-outils-opnsense01"
      flavor = "e4943d80-10a3-461c-a4a2-2d17ea114fb0"
      image  = "6b8be10a-b518-40a9-8883-8ac24c7f6861"
      networks = [
        { name = "outils-fw-interco-172.16.26.16-28", ip = "172.16.26.24", enabled = true },
        { name = "outils-fwbe-admin-10.16.50.0-24", ip = "10.16.50.254", enabled = true },
        { name = "outils-infra-admin-10.16.51.0-24", ip = "10.16.51.254", enabled = true },
        { name = "outils-dmz-admin-10.16.52.0-24", ip = "10.16.52.254", enabled = true },
        { name = "outils-k8s-10.16.61.0-24", ip = "10.16.61.254", enabled = true },
        { name = "outils-dmz-transit-10.16.70.0-24", ip = "10.16.70.254", enabled = true },
        { name = "outils-infra-app-10.16.90.0-24", ip = "10.16.90.254", enabled = true },
        { name = "outils-bastion-in-10.16.92.0-24", ip = "10.16.92.254", enabled = true },
      ]
      tags = { Owner = "infra-team", Env = "outils", Role = "opnsense" }
    }
  }
}
