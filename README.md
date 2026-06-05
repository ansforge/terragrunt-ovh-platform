# terraform-ovh-infra

Infrastructure as Code (IaC) pour les environnements OVHcloud, gérée avec **Terraform** et **Terragrunt**.

## Structure du projet

```
terraform-ovh-infra/
├── root.hcl                     # Configuration Terragrunt racine (backend S3, providers)
├── common.hcl                   # Variables partagées (environnements, régions, projets)
├── modules/
│   ├── storage/                 # Module : Object Storage (buckets S3)
│   ├── network/                 # Module : Réseaux privés (vRack, VLANs, subnets)
│   ├── security-cluster/        # Module : Clusters firewall (Stormshield)
│   │   └── stormshield/         # Sous-module : Instance Stormshield
│   ├── security-cluster-outils/ # Module : Security outils (OPNsense, Wallix)
│   └── foundation/              # Module : VMs socle (tfansible, proxy, repo, freeipa)
├── storage/
│   ├── prod/                    # Terragrunt : storage prod
│   ├── amont/                   # Terragrunt : storage amont
│   └── outils/                  # Terragrunt : storage outils
├── network/
│   ├── prod/                    # Terragrunt : network prod
│   ├── amont/                   # Terragrunt : network amont
│   └── outils/                  # Terragrunt : network outils
├── security/
│   ├── prod/                    # Terragrunt : security prod
│   ├── amont/                   # Terragrunt : security amont
│   └── outils/                  # Terragrunt : security outils
└── foundation/
    ├── prod/                    # Terragrunt : foundation prod
    ├── amont/                   # Terragrunt : foundation amont
    └── outils/                  # Terragrunt : foundation outils
```

## Environnements

| Environnement | Région | Usage |
|---|---|---|
| **prod** | RBX-A | Production |
| **amont** | SBG5 | Pré-production / Recette |
| **outils** | PAR (eu-west-par) | Outillage transverse |

## Layers (ordre de déploiement)

1. **storage** — Buckets S3 pour le backend Terraform et les données
2. **network** — Réseaux privés vRack, VLANs, subnets OpenStack
3. **security** — Firewalls Stormshield / OPNsense, bastions Wallix
4. **foundation** — VMs socle (Terraform/Ansible runner, proxy, repo, FreeIPA)

## Prérequis

- Terraform >= 1.12
- Terragrunt >= 0.80
- Accès Vault pour les credentials (OVH API, OpenStack, AWS S3)
- vRack configuré sur les projets OVHcloud

## Utilisation

```bash
# Se positionner dans un layer/environnement
cd network/prod

# Initialiser
terragrunt init

# Planifier
terragrunt plan

# Appliquer
terragrunt apply
```

### Déployer tous les layers d'un environnement

```bash
# Depuis la racine
terragrunt run-all plan --working-dir storage/prod network/prod security/prod foundation/prod
```

## Backend

Les states Terraform sont stockés dans des buckets S3 OVHcloud (un par environnement) :

| Environnement | Bucket | Région |
|---|---|---|
| prod | `infra-prod-sto-object-tf01` | RBX-A |
| amont | `infra-amont-sto-object-tf01` | SBG5 |
| outils | `infra-outils-sto-object-tf01` | eu-west-par |

## Secrets

Les credentials sont gérés via **HashiCorp Vault** :

| Mount | Secret | Usage |
|---|---|---|
| `iacrunner-{env}` | `aws_key` | S3 backend credentials |
| `iacrunner-{env}` | `ovh_key` | OVH API (application_key, application_secret, consumer_key) |
| `iacrunner-{env}` | `openstack_key` | OpenStack application credentials |

### Configuration des credentials

```bash
# Exporter les credentials S3 pour un environnement
export AWS_ACCESS_KEY_ID=$(vault kv get -mount="iacrunner-prod" -field=AWS_ACCESS_KEY_ID aws_key)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -mount="iacrunner-prod" -field=AWS_SECRET_ACCESS_KEY aws_key)
```

## Dépendances entre layers

```
storage ──► network ──► security ──► foundation
```

Chaque layer peut dépendre du précédent via les blocs `dependency` de Terragrunt.

## Migration

Ce dépôt est le résultat de la refactorisation de l'ancien mono-state Terraform en une architecture multi-layers Terragrunt (juin 2026).

### Principes de la migration

- Séparation du state monolithique en 4 layers indépendants par environnement
- Utilisation de modules Terraform partagés entre environnements
- Backend S3 OVHcloud avec clés distinctes par layer
- Credentials injectés dynamiquement via Vault (ephemeral resources)

## Convention de nommage

- **Réseaux** : `{env}-{zone}-{cidr}` (ex: `prod-production-infra-app-10.11.90.0-24`)
- **Instances** : `infra-{env}-{role}{index}` (ex: `infra-prod-fwfe01`)
- **Ports** : `port-{instance}-{network}` (ex: `port-infra-prod-fwfe01-prod-production-fw-front-5.135.49.0-25`)
- **Keypairs** : `key-{instance}` ou `vm-{role}-key`

## Contribution

1. Créer une branche feature depuis `main`
2. Modifier les modules ou les inputs Terragrunt
3. Valider avec `terragrunt plan` sur l'environnement **amont** en premier
4. Ouvrir une Pull Request
5. Appliquer après review et validation
