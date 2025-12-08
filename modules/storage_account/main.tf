module "azure_storage_account" {

  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.5.0"

  account_replication_type          = var.account_replication_type
  account_tier                      = var.account_tier
  account_kind                      = var.account_kind
  location                          = var.location
  name                              = var.name
  https_traffic_only_enabled        = true
  resource_group_name               = var.resource_group_name
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = var.public_network_access_enabled
  storage_management_policy_rule    = var.storage_management_policy_rule
  customer_managed_key = {
    key_vault_resource_id  = var.customer_managed_key_vault
    key_name               = azurerm_key_vault_key.main.name
    user_assigned_identity = { resource_id = azurerm_user_assigned_identity.main.id }
  }
  azure_files_authentication = var.azure_files_authentication
  blob_properties = {
    versioning_enabled = true
  }

  network_rules    = var.network_rules
  role_assignments = var.role_assignments
  containers       = var.containers
  enable_telemetry = false
  tags             = var.tags
}

resource "azurerm_key_vault_key" "main" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  key_type     = "RSA"
  key_vault_id = var.customer_managed_key_vault
  name         = var.name
  key_size     = 2048
}

resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = var.customer_managed_key_vault
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.main.principal_id

  key_permissions = ["Get", "Create", "List", "Restore", "Recover", "UnwrapKey", "WrapKey", "Purge", "Encrypt", "Decrypt", "Sign", "Verify"]
}

resource "azurerm_user_assigned_identity" "main" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
}