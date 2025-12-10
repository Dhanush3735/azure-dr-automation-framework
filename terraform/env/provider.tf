terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  # subscription_id and tenant_id should be set via environment variables:
  # ARM_SUBSCRIPTION_ID and ARM_TENANT_ID
  # Or via Azure CLI authentication
}