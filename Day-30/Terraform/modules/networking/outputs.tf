output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  value = azurerm_virtual_network.vnet.address_space
}

output "subnet_appgw_id" {
  value = azurerm_subnet.appgw.id
}

output "subnet_aks_id" {
  value = azurerm_subnet.aks.id
}

output "subnet_postgres_id" {
  value = azurerm_subnet.postgres.id
}

output "subnet_private_endpoints_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "subnet_appgw_cidr" {
  value = azurerm_subnet.appgw.address_prefixes
}

output "subnet_aks_cidr" {
  value = azurerm_subnet.aks.address_prefixes
}
