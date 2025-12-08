terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.95.0, < 4.0.0"
    }
  }
}
resource "azurerm_resource_group" "main" {
  name       = var.name
  location   = var.location
  tags       = var.tags
  managed_by = var.managed_by
}
