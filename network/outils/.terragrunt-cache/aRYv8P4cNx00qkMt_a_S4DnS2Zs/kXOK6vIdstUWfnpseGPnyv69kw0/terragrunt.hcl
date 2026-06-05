include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common     = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env        = "outils"
  env_config = local.common.locals.environments[local.env]
}

terraform {
  source = "${get_repo_root()}/modules/network"
}

dependency "storage" {
  config_path = "../../storage/outils"
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
    "vrack_vpn"       = { vlan_id = 510, name = "outils-vrack-vpn-10.15.10.0-24", cidr = "10.15.10.0/24", start = "10.15.10.51", end = "10.15.10.100" }
    "fwfe_admin"      = { vlan_id = 520, name = "outils-fwfe-admin-10.15.20.0-24", cidr = "10.15.20.0/24", start = "10.15.20.51", end = "10.15.20.100" }
    "dmz_exposed"     = { vlan_id = 530, name = "outils-dmz-exposed-10.15.30.0-24", cidr = "10.15.30.0/24", start = "10.15.30.51", end = "10.15.30.100", enable_dhcp = true, gateway_ip = "10.15.30.254" }
    "fw_interco_iaas" = { vlan_id = 640, name = "outils-fw-interco-172.16.26.16-28", cidr = "172.16.26.16/28", start = "172.16.26.17", end = "172.16.26.26" }
    "fwbe_admin"      = { vlan_id = 650, name = "outils-fwbe-admin-10.16.50.0-24", cidr = "10.16.50.0/24", start = "10.16.50.51", end = "10.16.50.100" }
    "infra_admin"     = { vlan_id = 651, name = "outils-infra-admin-10.16.51.0-24", cidr = "10.16.51.0/24", start = "10.16.51.51", end = "10.16.51.100" }
    "dmz_admin"       = { vlan_id = 652, name = "outils-dmz-admin-10.16.52.0-24", cidr = "10.16.52.0/24", start = "10.16.52.51", end = "10.16.52.100" }
    "k8s"             = { vlan_id = 661, name = "outils-k8s-10.16.61.0-24", cidr = "10.16.61.0/24", start = "10.16.61.51", end = "10.16.61.100" }
    "dmz_transit"     = { vlan_id = 670, name = "outils-dmz-transit-10.16.70.0-24", cidr = "10.16.70.0/24", start = "10.16.70.51", end = "10.16.70.100" }
    "infra_app"       = { vlan_id = 690, name = "outils-infra-app-10.16.90.0-24", cidr = "10.16.90.0/24", start = "10.16.90.51", end = "10.16.90.100", enable_dhcp = true, gateway_ip = "10.16.90.253" }
    "bastion_in"      = { vlan_id = 692, name = "outils-bastion-in-10.15.92.0-24", cidr = "10.16.92.0/24", start = "10.16.92.51", end = "10.16.92.100" }
    "fw_front"        = { vlan_id = 0, name = "outils-fw-front-57.130.50.224-28", cidr = "57.130.50.224/28", start = "57.130.50.225", end = "57.130.50.238" }
  }
}
