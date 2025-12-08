output "dns_zone_id" {
  value = azurerm_private_dns_zone.main.id
}

output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = azurerm_private_dns_zone.main.name
}