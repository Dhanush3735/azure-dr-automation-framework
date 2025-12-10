output "resource_group_name" {
  value = var.resource_group_name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "vnet_subnets" {
  value = module.network.vnet_subnets
}

output "network_security_group_ids" {
  value = { for k, nsg in azurerm_network_security_group.main : k => nsg.id }
}

output "subnet_nsg_associations" {
  value = { for k, assoc in azurerm_subnet_network_security_group_association.main : k => assoc.network_security_group_id }
}

