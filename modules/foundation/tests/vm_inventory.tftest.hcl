# Tests unitaires du module foundation — fournisseurs simulés (aucun appel OpenStack).
# Exécution : cd modules/foundation && terraform init -backend=false && terraform test

mock_provider "openstack" {
  # Valeurs simulées appliquées à toutes les instances de ressource du type.
  mock_resource "openstack_networking_port_v2" {
    defaults = {
      all_fixed_ips = ["10.99.90.50"]
      mac_address   = "fa:16:3e:00:00:01"
    }
  }

  mock_resource "openstack_compute_instance_v2" {
    defaults = {
      access_ip_v4 = "51.0.0.10"
    }
  }

  mock_data "openstack_networking_subnet_v2" {
    defaults = {
      cidr       = "10.99.90.0/24"
      gateway_ip = "10.99.90.254"
    }
  }

  mock_data "openstack_images_image_v2" {
    defaults = {
      id = "img-almalinux-10"
    }
  }
}

mock_provider "tls" {}

variables {
  region         = "TEST-1"
  ovh_project_id = "test"

  vms = {
    app01 = {
      name        = "infra-test-app01"
      flavor_id   = "flavor-c3-4"
      image_name  = "AlmaLinux 10"
      key_name    = "unused"
      extra_disks = [{ size = 20 }]
      networks = [
        { name = "test-infra-app-10.99.90.0-24", ip = "10.99.90.50", enabled = true },
        { name = "test-dmz-transit-10.99.70.0-24", ip = "10.99.70.50", enabled = true },
      ]
      tags = { Env = "test", App = "app", AnsibleGroups = "infra_test" }
    }

    gw01 = {
      name          = "infra-test-gw01"
      flavor_id     = "flavor-c3-4"
      image_id      = "img-legacy"
      key_name      = "unused"
      extra_disk_gb = 10
      networks = [
        { name = "Ext-Net", ip = "", enabled = true },
        { name = "test-infra-app-10.99.90.0-24", ip = "10.99.90.51", enabled = true },
      ]
      tags = { Env = "test" }
    }
  }
}

run "vm_inventory_expose_les_donnees_de_provisionnement" {
  command = apply

  assert {
    condition     = output.vm_inventory["app01"].name == "infra-test-app01"
    error_message = "Le nom OpenStack de la VM doit être exposé."
  }

  assert {
    condition     = output.vm_inventory["app01"].image_id == "img-almalinux-10" && output.vm_inventory["gw01"].image_id == "img-legacy"
    error_message = "L'image effective (résolue par nom ou par ID) doit être exposée."
  }

  assert {
    condition     = length(output.vm_inventory["app01"].networks) == 2 && output.vm_inventory["app01"].networks[0].primary && !output.vm_inventory["app01"].networks[1].primary
    error_message = "Les réseaux doivent être exposés dans l'ordre de déclaration, le premier étant primaire."
  }

  assert {
    condition = (
      output.vm_inventory["app01"].networks[1].name == "test-dmz-transit-10.99.70.0-24" &&
      output.vm_inventory["app01"].networks[1].ip == "10.99.90.50" &&
      output.vm_inventory["app01"].networks[1].mac == "fa:16:3e:00:00:01" &&
      output.vm_inventory["app01"].networks[1].cidr == "10.99.90.0/24" &&
      output.vm_inventory["app01"].networks[1].gateway == "10.99.90.254"
    )
    error_message = "Chaque réseau privé doit exposer IP, MAC, CIDR et passerelle (valeurs simulées)."
  }

  assert {
    condition = (
      output.vm_inventory["gw01"].networks[0].name == "Ext-Net" &&
      output.vm_inventory["gw01"].networks[0].ip == "51.0.0.10" &&
      output.vm_inventory["gw01"].networks[0].mac == null &&
      output.vm_inventory["gw01"].networks[0].cidr == null
    )
    error_message = "Ext-Net doit exposer l'IP d'accès de l'instance, sans MAC ni CIDR."
  }

  assert {
    condition = (
      length(output.vm_inventory["app01"].volumes) == 1 &&
      output.vm_inventory["app01"].volumes[0].key == "app01_data1" &&
      output.vm_inventory["app01"].volumes[0].size == 20 &&
      length(output.vm_inventory["gw01"].volumes) == 1 &&
      output.vm_inventory["gw01"].volumes[0].key == "gw01" &&
      output.vm_inventory["gw01"].volumes[0].size == 10
    )
    error_message = "Les volumes (mécanismes extra_disks et extra_disk_gb) doivent être rattachés à leur VM."
  }

  assert {
    condition     = output.vm_inventory["app01"].tags["AnsibleGroups"] == "infra_test"
    error_message = "Les tags (dont les métadonnées Ansible) doivent être exposés."
  }
}
