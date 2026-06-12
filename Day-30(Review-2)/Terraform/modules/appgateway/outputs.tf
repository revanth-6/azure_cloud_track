output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

output "appgw_name" {
  value = azurerm_application_gateway.appgw.name
}

output "public_ip_address" {
  value = azurerm_public_ip.appgw.ip_address
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.appgw.fqdn
}
