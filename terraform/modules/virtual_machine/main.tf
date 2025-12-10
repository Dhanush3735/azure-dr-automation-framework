module "virtual_machine" {
  source              = "Azure/virtual-machine/azurerm"
  version             = "1.1.0"
  for_each            = toset([for i in range(var.vm_count) : tostring(i)])
  name                = "${var.vm_name}-${each.key}"
  location            = var.location
  image_os            = var.image_os
  size                = var.vm_size
  os_disk             = local.os_disk
  data_disks          = local.data_disks
  subnet_id           = var.subnet_id
  resource_group_name = var.resource_group_name
  new_network_interface = var.new_network_interface != null ? merge(var.new_network_interface, {
    enable_accelerated_networking = local.standard_nic_config.enable_accelerated_networking
    dns_servers                   = local.standard_nic_config.dns_servers
  }) : null

  admin_username = var.admin_username
  admin_ssh_keys = var.admin_ssh_keys
  tags           = var.tags
}

resource "azurerm_disk_encryption_set" "main" {
  key_vault_key_id    = azurerm_key_vault_key.main.id
  location            = var.location
  name                = "${var.vm_name}-des"
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_key" "main" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "wrapKey",
    "unwrapKey",
    "verify",
  ]
  key_type     = "RSA"
  key_vault_id = var.disk_encryption_set_key_vault_id
  name         = "${var.vm_name}-des-key"
  key_size     = 2048
}

# Access policy for disk encryption key usage by VM's system-assigned identity
resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = var.disk_encryption_set_key_vault_id
  object_id    = azurerm_disk_encryption_set.main.identity.principal_id
  tenant_id    = azurerm_disk_encryption_set.main.identity.tenant_id
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
  ]
}

resource "azurerm_private_dns_a_record" "main" {
  for_each = local.vm_private_ips

  name                = var.vm_count == 1 ? var.dns_record_name : "${var.dns_record_name}-${each.key}"
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [each.value]
}


