# ─────────────────────────────────────────────────────────────────
# _settings.hcl — Versions Terraform et providers requis
# ─────────────────────────────────────────────────────────────────

locals {
  terraform_version = ">= 1.10.0"

  providers = {
    openstack = { source = "terraform-provider-openstack/openstack", version = ">= 1.53.0" }
    ovh       = { source = "ovh/ovh", version = ">= 2.11.0" }
    vault     = { source = "hashicorp/vault", version = ">= 3.25.0" }
    tls       = { source = "hashicorp/tls", version = ">= 4.0.0" }
    aws       = { source = "hashicorp/aws", version = ">= 5.0.0" }
  }
}
