output "fitness_nsg_id" {
  value = azurerm_network_security_group.fitness.id
}

output "organic_nsg_id" {
  value = azurerm_network_security_group.organic.id
}

output "appgw_nsg_id" {
  value = azurerm_network_security_group.appgw.id
}