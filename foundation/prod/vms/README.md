# Déclaration des VMs par fichiers YAML

Chaque fichier `<cle_vm>.yaml` de ce dossier déclare **une** VM du layer `foundation` de l'environnement.
Les fichiers sont chargés par `terragrunt.hcl` (`local.vm_specs`) et fusionnés avec les VMs déclarées inline.
Le même mécanisme existe pour `foundation/amont` et `foundation/outils` (créer le dossier `vms/` au besoin).

- Le **nom du fichier** (sans `.yaml`) est la **clé Terraform** de la VM : minuscules, chiffres et tirets
  uniquement (`^[a-z0-9][a-z0-9-]*$`). Pas de `_` (séparateur utilisé dans les clés des ports/disques).
- Le **schéma** est celui de la variable `vms` du module `modules/foundation` (voir `variables.tf`).
- Une VM déclarée **inline** dans `terragrunt.hcl` reste **prioritaire** : un fichier YAML portant la même clé est
  ignoré par Terragrunt et **rejeté** par la pipeline (`ovh-vm`).
- Mettre les valeurs ambiguës entre guillemets (ex. `Version: "1.10"`), YAML typant automatiquement les nombres.

```yaml
# vms/spw-preprod2.yaml
name: spw-preprod-rp02
flavor_id: 94d7bb57-156a-4e7d-8840-1e9e4bcbe304   # c3-4
image_name: AlmaLinux 10                          # ou image_id
key_name: vm-spw-preprod2-key                     # informatif : la paire créée s'appelle vm-<cle_vm>-key
extra_disks:                                      # optionnel
  - name: spw-preprod-rp02-data01
    size: 50
networks:                                         # le 1er réseau privé porte l'IP de connexion Ansible
  - name: prod-production-infra-app-10.11.90.0-24
    ip: 10.11.90.20
    enabled: true
  - name: mie_preproduction_front-10.0.6.96-27
    ip: 10.0.6.101
    enabled: true
tags:
  Owner: app-team
  Env: preprod
  App: spw
  AnsibleGroups: mie_preprod      # groupes d'inventaire Ansible supplémentaires (séparés par des virgules)
  AnsibleProfile: standard        # profil de provisionnement : minimal | standard | hardened | full
```

Les tags `Ansible*` sont posés en métadonnées OpenStack et lus par la pipeline de provisionnement
(dépôt `ovh-vm-pipeline`) pour placer la VM dans les bons groupes d'inventaire et choisir les étapes Ansible.

> Rappel : `ignore_changes` du module empêche toute modification ultérieure de `flavor_id`, `image_*`, `networks`
> ou `tags` d'une VM existante via Terraform. Ces champs ne sont pris en compte qu'à la création.
