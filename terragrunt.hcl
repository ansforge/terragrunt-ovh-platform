# ─────────────────────────────────────────────────────────────────
# terragrunt.hcl (RACINE) — Configuration globale DRY
# ─────────────────────────────────────────────────────────────────

locals {
  # Charger les inputs communs
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Déterminer l'environnement à partir du chemin du dossier
  # Ex: foundation/prod/terragrunt.hcl → env = "prod"
  env = basename(get_terragrunt_dir())

  # Mapping environnement → région S3 et endpoint
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
      region   = "sbg"
      endpoint = "https://s3.sbg.io.cloud.ovh.net/"
    }
    test = {
      bucket   = "infra-test-sto-object-tf01"
      region   = "sbg"
      endpoint = "https://s3.sbg.io.cloud.ovh.net/"
    }
  }
}

# ─── Backend S3 DRY (généré automatiquement) ───
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

# ─── Génération du fichier provider Vault (commun à tous les layers) ───
generate "provider_vault" {
  path      = "_provider_vault.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-PROVIDERS
    provider "vault" {
      skip_child_token = true
    }
  PROVIDERS
}
