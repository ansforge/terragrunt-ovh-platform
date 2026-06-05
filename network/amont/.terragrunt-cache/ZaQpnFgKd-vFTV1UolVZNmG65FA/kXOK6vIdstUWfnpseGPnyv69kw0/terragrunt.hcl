include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "amont"
  env_config = local.common.locals.environments[local.env]
}

terraform {
  source = "${get_repo_root()}/modules/network"
}

dependency "storage" {
  config_path = "../../storage/amont"
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
    "fw_front"     = { vlan_id = 0, name = "preprod-amont-fw-front-5.196.116.80-28", cidr = "5.196.116.80/28", start = "5.196.116.81", end = "5.196.116.94" }
    "vrack_vpn"    = { vlan_id = 210, name = "preprod-amont-vrack-vpn-10.12.10.0-24", cidr = "10.12.10.0/24", start = "10.12.10.51", end = "10.12.10.100" }
    "fwfe_admin"   = { vlan_id = 220, name = "preprod-amont-fwfe-admin-10.12.20.0-24", cidr = "10.12.20.0/24", start = "10.12.20.51", end = "10.12.20.100" }
    "dmz_exposed"  = { vlan_id = 230, name = "preprod-amont-dmz-exposed-10.12.30.0-24", cidr = "10.12.30.0/24", start = "10.12.30.51", end = "10.12.30.100", enable_dhcp = true, gateway_ip = "10.12.30.254" }
    "fw_interco"   = { vlan_id = 240, name = "preprod-amont-fw-interco-172.16.31.16-28", cidr = "172.16.31.16/28", start = "172.16.31.17", end = "172.16.31.30" }
    "fwbe_admin"   = { vlan_id = 250, name = "preprod-amont-fwbe-admin-10.12.50.0-24", cidr = "10.12.50.0/24", start = "10.12.50.51", end = "10.12.50.100" }
    "infra_admin"  = { vlan_id = 251, name = "preprod-amont-infra-admin-10.12.51.0-24", cidr = "10.12.51.0/24", start = "10.12.51.51", end = "10.12.51.100" }
    "dmz_admin"    = { vlan_id = 252, name = "preprod-amont-dmz-admin-10.12.52.0-24", cidr = "10.12.52.0/24", start = "10.12.52.51", end = "10.12.52.100", enable_dhcp = true, gateway_ip = "10.12.52.251" }
    "k8s_front"    = { vlan_id = 260, name = "preprod-amont-k8s-front-10.12.60.0-24", cidr = "10.12.60.0/24", start = "10.12.60.51", end = "10.12.60.100" }
    "k8s_back"     = { vlan_id = 261, name = "preprod-amont-k8s-back-10.12.61.0-24", cidr = "10.12.61.0/24", start = "10.12.61.51", end = "10.12.61.100" }
    "dmz_transit"  = { vlan_id = 270, name = "preprod-amont-dmz-transit-10.12.70.0-24", cidr = "10.12.70.0/24", start = "10.12.70.51", end = "10.12.70.100", enable_dhcp = false }
    "infra_app"    = { vlan_id = 290, name = "preprod-amont-infra-app-10.12.90.0-24", cidr = "10.12.90.0/24", start = "10.12.90.51", end = "10.12.90.100", enable_dhcp = true, gateway_ip = "10.12.90.251" }
    "app_front"    = { vlan_id = 400, name = "preprod-amont-app-front-10.14.0.0-24", cidr = "10.14.0.0/24", start = "10.14.0.51", end = "10.14.0.100" }
    "app_middle"   = { vlan_id = 401, name = "preprod-amont-app-middle-10.14.1.0-24", cidr = "10.14.1.0/24", start = "10.14.1.51", end = "10.14.1.100" }
    "app_back"     = { vlan_id = 402, name = "preprod-amont-app-back-10.14.2.0-24", cidr = "10.14.2.0/24", start = "10.14.2.51", end = "10.14.2.100" }
  }
}
