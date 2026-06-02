include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "prod"
  env_config = local.common.locals.environments[local.env]
  module_conf = read_terragrunt_config("${get_parent_terragrunt_dir()}/module.hcl")
}

terraform {
  source = local.module_conf.locals.module_source
}

dependency "storage" {
  config_path = "../../storage/prod"
  mock_outputs = {
    s3_access_key = "mock"
    s3_secret_key = "mock"
  }
}

generate "providers" {
  path      = "_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-PROVIDERS
    ephemeral "vault_kv_secret_v2" "ovh" {
      mount = "${local.env_config.vault_mount}"
      name  = "ovh_key"
    }

    ephemeral "vault_kv_secret_v2" "os" {
      mount = "${local.env_config.vault_mount}"
      name  = "openstack_key"
    }

    locals {
      ovh_creds = ephemeral.vault_kv_secret_v2.ovh.data
      os_creds  = ephemeral.vault_kv_secret_v2.os.data
    }

    provider "ovh" {
      endpoint           = "ovh-eu"
      application_key    = local.ovh_creds["OVH_APPLICATION_KEY"]
      application_secret = local.ovh_creds["OVH_APPLICATION_SECRET"]
      consumer_key       = local.ovh_creds["OVH_CONSUMER_KEY"]
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
  service_name = local.env_config.ovh_project_id
  region       = local.env_config.region

  vlans = {
    "vrack_vpn"   = { vlan_id = 110, name = "prod-production-vrack-vpn-10.11.10.0-24", cidr = "10.11.10.0/24", start = "10.11.10.51", end = "10.11.10.100" }
    "fwfe_admin"  = { vlan_id = 120, name = "prod-production-fwfe-admin-10.11.20.0-24", cidr = "10.11.20.0/24", start = "10.11.20.51", end = "10.11.20.100" }
    "fwfe_ha"     = { vlan_id = 121, name = "prod-production-fwfe-ha-172.16.21.32-28", cidr = "172.16.21.32/28", start = "172.16.21.43", end = "172.16.21.46" }
    "fw_interco"  = { vlan_id = 140, name = "prod-production-fw-interco-172.16.21.16-28", cidr = "172.16.21.16/28", start = "172.16.21.27", end = "172.16.21.30" }
    "fwbe_admin"  = { vlan_id = 150, name = "prod-production-fwbe-admin-10.11.50.0-24", cidr = "10.11.50.0/24", start = "10.11.50.51", end = "10.11.50.100" }
    "infra_admin" = { vlan_id = 151, name = "prod-production-infra-admin-10.11.51.0-24", cidr = "10.11.51.0/24", start = "10.11.51.51", end = "10.11.51.100" }

    "dmz_admin" = {
      vlan_id    = 152
      name       = "prod-production-dmz-admin-10.11.52.0-24"
      cidr       = "10.11.52.0/24"
      start      = "10.11.52.51"
      end        = "10.11.52.100"
      enable_dhcp = true
      gateway_ip = "10.11.52.254"
    }

    "k8s_front"  = { vlan_id = 160, name = "prod-production-k8s-front-10.11.60.0-24", cidr = "10.11.60.0/24", start = "10.11.60.51", end = "10.11.60.100" }
    "k8s_back"   = { vlan_id = 161, name = "prod-production-k8s-back-10.11.61.0-24", cidr = "10.11.61.0/24", start = "10.11.61.51", end = "10.11.61.100" }

    "dmz_transit" = {
      vlan_id     = 170
      name        = "prod-production-dmz-transit-10.11.70.0-24"
      cidr        = "10.11.70.0/24"
      start       = "10.11.70.51"
      end         = "10.11.70.100"
      enable_dhcp = false
    }

    "fw_front"   = { vlan_id = 0, name = "prod-production-fw-front-5.135.49.0-25", cidr = "5.135.49.0/25", start = "5.135.49.1", end = "5.135.49.126" }
    "app_front"  = { vlan_id = 300, name = "prod-production-app-front-10.13.0.0-24", cidr = "10.13.0.0/24", start = "10.13.0.51", end = "10.13.0.100" }
    "app_middle" = { vlan_id = 301, name = "prod-production-app-middle-10.13.1.0-24", cidr = "10.13.1.0/24", start = "10.13.1.51", end = "10.13.1.100" }
    "app_back"   = { vlan_id = 302, name = "prod-production-app-back-10.13.2.0-24", cidr = "10.13.2.0/24", start = "10.13.2.51", end = "10.13.2.100" }

    "infra_app" = {
      vlan_id     = 190
      name        = "prod-production-infra-app-10.11.90.0-24"
      cidr        = "10.11.90.0/24"
      start       = "10.11.90.51"
      end         = "10.11.90.100"
      enable_dhcp = true
      gateway_ip  = "10.11.90.254"
    }

    "dmz_exposed" = {
      vlan_id     = 130
      name        = "prod-production-dmz-exposed-10.11.30.0-24"
      cidr        = "10.11.30.0/24"
      start       = "10.11.30.51"
      end         = "10.11.30.100"
      enable_dhcp = true
      gateway_ip  = "10.11.30.251"
    }
  }
}
