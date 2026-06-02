# ─────────────────────────────────────────────────────────────────
# common.hcl — Variables partagées entre TOUS les environnements
# ─────────────────────────────────────────────────────────────────

locals {
  # Mapping environnement → configuration OVH
  environments = {
    prod = {
      ovh_project_id = "2b264defd5244f52b8edbd6c9239a325"
      region         = "RBX-A"
      vault_mount    = "iacrunner-prod"
      name_prefix    = "infra-prod"
      net_prefix     = "prod-production"
    }
    amont = {
      ovh_project_id = "a5a3658023e146e78a22afd04601b813"
      region         = "SBG5"
      vault_mount    = "iacrunner-amont"
      name_prefix    = "infra-amont"
      net_prefix     = "preprod-amont"
    }
    outils = {
      ovh_project_id = "XXXXXXXX"  # À compléter
      region         = "SBG5"
      vault_mount    = "iacrunner-outils"
      name_prefix    = "infra-outils"
      net_prefix     = "outils"
    }
    test = {
      ovh_project_id = "XXXXXXXX"  # À compléter
      region         = "SBG5"
      vault_mount    = "iacrunner-test"
      name_prefix    = "infra-test"
      net_prefix     = "test"
    }
  }
}
