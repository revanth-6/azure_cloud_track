output "vnet_name" {
  value       = azurerm_virtual_network.main.name
  description = "Virtual Network name"
}

output "vnet_id" {
  value       = azurerm_virtual_network.main.id
  description = "Virtual Network ID"
}

output "appgw_subnet_id" {
  value       = azurerm_subnet.appgw.id
  description = "App Gateway Subnet ID"
}

output "frontend_subnet_id" {
  value       = azurerm_subnet.frontend.id
  description = "Frontend Subnet ID"
}

output "microservices_subnet_id" {
  value       = azurerm_subnet.microservices.id
  description = "Microservices Subnet ID"
}

output "postgres_subnet_id" {
  value       = azurerm_subnet.postgres.id
  description = "Postgres Subnet ID"
}

output "private_dns_zone_id" {
  value       = azurerm_private_dns_zone.postgres.id
  description = "Postgres Private DNS Zone ID"
}

output "private_dns_zone_name" {
  value       = azurerm_private_dns_zone.postgres.name
  description = "Postgres Private DNS Zone name"
}
