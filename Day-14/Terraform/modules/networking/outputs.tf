output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "fitness_subnet_id" {
  value = azurerm_subnet.fitness.id
}

output "organic_subnet_id" {
  value = azurerm_subnet.organic.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}