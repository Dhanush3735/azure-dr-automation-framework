resource "azurerm_recovery_services_vault" "main" {
  name                         = var.recovery_vault_name
  location                     = var.recovery_vault_location
  resource_group_name          = var.resource_group_name
  sku                          = var.recovery_vault_sku
  storage_mode_type            = var.storage_mode_type
  cross_region_restore_enabled = var.cross_region_restore_enabled
  soft_delete_enabled          = var.soft_delete_enabled
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_backup_policy_vm" "main" {
  for_each                       = var.backup_policies
  name                           = each.key
  resource_group_name            = azurerm_recovery_services_vault.main.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.main.name
  timezone                       = each.value.timezone
  policy_type                    = each.value.policy_type
  instant_restore_retention_days = each.value.instant_restore_retention_days

  backup {
    frequency = each.value.backup_frequency
    time      = each.value.backup_time
  }

  dynamic "retention_daily" {
    for_each = each.value.retention.daily_backups_retention != null ? [1] : []
    content {
      count = each.value.retention.daily_backups_retention
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.retention.weekly_backups_retention != null ? [1] : []
    content {
      count    = each.value.retention.weekly_backups_retention
      weekdays = each.value.retention.weekdays
    }
  }
}

