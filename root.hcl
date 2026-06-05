locals {
  env = basename(get_terragrunt_dir())

  env_config = {
    prod = {
      bucket   = "infra-prod-sto-object-tf01"
      region   = "rbx"
      endpoint = "https://s3.rbx.io.cloud.ovh.net/"
    }
    amont = {
      bucket   = "infra-amont-sto-object-tf01"
      region   = "sbg"
      endpoint = "https://s3.sbg.io.cloud.ovh.net/"
    }
    outils = {
      bucket   = "infra-outils-sto-object-tf01"
      region   = "eu-west-par"
      endpoint = "https://s3.eu-west-par.io.cloud.ovh.net/"
    }
    test = {
      bucket   = "infra-test-sto-object-tf01"
      region   = "sbg"
      endpoint = "https://s3.sbg.io.cloud.ovh.net/"
    }
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = local.env_config[local.env].bucket
    key    = "${path_relative_to_include()}.tfstate"
    region = local.env_config[local.env].region

    endpoints = {
      s3 = local.env_config[local.env].endpoint
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}

generate "provider_vault" {
  path      = "_provider_vault.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-PROVIDERS
    provider "vault" {
      skip_child_token = true
    }
  PROVIDERS
}
