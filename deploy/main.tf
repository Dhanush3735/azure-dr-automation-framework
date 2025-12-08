# Module to create Azure Resource Groups

module "resource_group" {
  source = "./modules/resource_group"

  name       = var.virtual_network_configuration["resource_group_name"]
  location   = var.virtual_network_configuration["resource_group_location"]
  tags       = var.common_tags
  managed_by = null
}

# Module to create Virtual Networks

module "virtual_network" {
  source = "./modules/virtual_network"

  depends_on                                                            = [module.resource_group]
  resource_group_name                                                   = module.resource_group.resource_group_name
  resource_group_location                                               = module.resource_group.resource_group_location
  virtual_network_name                                                  = var.virtual_network_configuration["virtual_network_name"]
  virtual_network_address_spaces                                        = var.virtual_network_configuration["virtual_network_address_spaces"]
  virtual_network_subnet_names                                          = var.virtual_network_configuration["virtual_network_subnet_names"]
  virtual_network_subnet_prefixes                                       = var.virtual_network_configuration["virtual_network_subnet_prefixes"]
  virtual_network_subnet_service_endpoints                              = var.virtual_network_configuration["virtual_network_subnet_service_endpoints"]
  virtual_network_subnet_delegation                                     = var.virtual_network_configuration["virtual_network_subnet_delegation"]
  virtual_network_subnet_enforce_private_link_endpoint_network_policies = var.virtual_network_configuration["virtual_network_subnet_enforce_private_link_endpoint_network_policies"]
  virtual_network_peers                                                 = var.virtual_network_configuration["virtual_network_peers"]
  nsg_definitions                                                       = try(var.virtual_network_configuration, "nsg_definitions", {})
  subnet_nsg_map                                                        = try(var.virtual_network_configuration, "subnet_nsg_map", {})
  tags                                                                  = var.common_tags
}

# Module for creating Private DNS

module "private_dns" {
  source = "./modules/private_dns"

  resource_group_name = module.resource_group.resource_group_name
  dns_zone_name       = var.dns_config.zone_name
  tags                = var.common_tags

  # Link the DNS zone to the VNET for private resolution
  vnet_links = [
    {
      name                 = var.dns_config.vnet_link_name
      virtual_network_id   = module.virtual_network.vnet_id
      registration_enabled = var.dns_config.registration_enabled
    }
  ]
}

# Module to create Storage account

module "storage_account" {
  source = "./modules/storage_account"

  name                          = var.storage_account_config["name"]
  resource_group_name           = var.storage_account_config["resource_group_name"]
  location                      = var.storage_account_config["location"]
  customer_managed_key_vault    = module.storage_account_keys.azurerm_key_vault_id
  account_replication_type      = var.storage_account_config["account_replication_type"]
  role_assignments              = var.storage_account_config["role_assignments"]
  containers                    = var.storage_account_config["containers"]
  public_network_access_enabled = var.storage_account_config["public_network_access_enabled"]
  network_rules                 = var.storage_account_config["network_rules"]
}

# Module to create Key Vault for Storage account

module "storage_account_keys" {
  source = "./modules/key_vault"

  name                        = lookup(var.storage_account_encryption_key_vault_config, "name", "")
  location                    = var.storage_account_encryption_key_vault_config["resource_group_location"]
  resource_group_name         = var.storage_account_encryption_key_vault_config["resource_group_name"]
  enabled_for_disk_encryption = var.storage_account_encryption_key_vault_config["enabled_for_disk_encryption"]
  tenant_id                   = var.tenant_id
  object_id                   = var.object_id
}

# Module to create Recovery Service Vault

module "recovery_services_vault" {
  source = "./modules/recovery_services_vault"

  recovery_vault_name          = var.recovery_services_vault_config["recovery_vault_name"]
  recovery_vault_location      = var.recovery_services_vault_config["recovery_vault_location"]
  resource_group_name          = var.recovery_services_vault_config["resource_group_name"]
  recovery_vault_sku           = var.recovery_services_vault_config["recovery_vault_sku"]
  storage_mode_type            = var.recovery_services_vault_config["storage_mode_type"]
  cross_region_restore_enabled = var.recovery_services_vault_config["cross_region_restore_enabled"]
  soft_delete_enabled          = var.recovery_services_vault_config["soft_delete_enabled"]
  backup_policies              = var.recovery_services_vault_config["backup_policies"]
}

# Module to create a Virtual Machine

module "vm01" {
  source = "./modules/virtual_machine"

  vm_name                          = var.vm01_config["vm_name"]
  vm_count                         = var.vm01_config["count"]
  vm_size                          = var.vm01_config["vm_size"]
  image_os                         = var.vm01_config["image_os"]
  zone_name                        = var.vm01_config["zone_name"]
  os_disk                          = var.vm01_config["os_disk"]
  data_disks                       = var.vm01_config["data_disks"]
  location                         = var.vm01_config["resource_group_location"]
  admin_username                   = var.vm01_config["admin_username"]
  admin_ssh_keys                   = var.vm01_config["admin_ssh_keys"]
  subnet_id                        = var.vm01_config["subnet_id"]
  new_network_interface            = var.vm01_config["new_network_interface"]
  disk_encryption_set_key_vault_id = module.storage_account_keys.azurerm_key_vault_id
  resource_group_name              = module.resource_group.resource_group_name
  tags                             = var.common_tags
}