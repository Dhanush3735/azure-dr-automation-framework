module "network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"

  resource_group_name                                   = var.resource_group_name
  resource_group_location                               = var.resource_group_location
  virtual_network_name                                  = var.virtual_network_name
  address_spaces                                        = var.virtual_network_address_spaces
  subnet_prefixes                                       = var.virtual_network_subnet_prefixes
  subnet_names                                          = var.virtual_network_subnet_names
  subnet_service_endpoints                              = var.virtual_network_subnet_service_endpoints
  subnet_delegation                                     = var.virtual_network_subnet_delegation
  subnet_enforce_private_link_endpoint_network_policies = var.virtual_network_subnet_enforce_private_link_endpoint_network_policies
  use_for_each                                          = true
  tags                                                  = var.tags
}

resource "azurerm_network_security_group" "main" {
  for_each = var.nsg_definitions

  name                = each.key
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tags                = each.value.tags
}

resource "azurerm_network_security_rule" "main" {
  for_each = merge([
    for nsg_name, nsg in var.nsg_definitions : {
      for rule in nsg.rules :
      "${nsg_name}.${rule.name}" => {
        nsg_name = nsg_name
        rule     = rule
      }
    }
  ]...)

  name                        = each.value.rule.name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = each.value.rule.source_port_range
  destination_port_range      = each.value.rule.destination_port_range
  source_address_prefix       = each.value.rule.source_address_prefix
  destination_address_prefix  = each.value.rule.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[each.value.nsg_name].name
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnet_nsg_map

  subnet_id                 = [for subnet in module.network.virtual_network_subnets : subnet if element(split("/", subnet), length(split("/", subnet)) - 1) == each.key][0]
  network_security_group_id = azurerm_network_security_group.main[each.value].id
}

resource "azurerm_virtual_network_peering" "main" {
  for_each = { for obj in var.virtual_network_peers : obj.name => obj }

  name                         = each.value["name"]
  resource_group_name          = var.resource_group_name
  virtual_network_name         = module.network.virtual_network_name
  remote_virtual_network_id    = each.value["remote_virtual_network_id"]
  allow_virtual_network_access = each.value["allow_virtual_network_access"]
  allow_forwarded_traffic      = each.value["allow_forwarded_traffic"]
  use_remote_gateways          = each.value["use_remote_gateways"]
}