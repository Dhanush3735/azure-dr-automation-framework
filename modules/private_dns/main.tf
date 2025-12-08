resource "azurerm_private_dns_zone" "main" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "main" {
  for_each = { for record in var.a_records : record.name => record }

  name                = each.value.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
}

resource "azurerm_private_dns_aaaa_record" "main" {
  for_each = { for record in var.aaaa_records : record.name => record }

  name                = each.value.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
}

resource "azurerm_private_dns_cname_record" "main" {
  for_each = { for record in var.cname_records : record.name => record }

  name                = each.value.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
}

resource "azurerm_private_dns_txt_record" "main" {
  for_each = { for record in var.txt_records : record.name => record }

  name                = each.value.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }
}

resource "azurerm_private_dns_mx_record" "main" {
  for_each = { for record in var.mx_records : record.name => record }

  name                = each.value.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  record {
    preference = each.value.priority
    exchange   = each.value.exchange
  }
}

resource "azurerm_private_dns_srv_record" "main" {
  for_each = { for record in var.srv_records : record.name => record }

  name                = each.value.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  record {
    priority = each.value.priority
    weight   = each.value.weight
    port     = each.value.port
    target   = each.value.target
  }
}


resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = { for link in var.vnet_links : link.name => link }

  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = var.dns_zone_name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
}

