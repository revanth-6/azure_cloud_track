output "appgw_id" {
  value       = azurerm_application_gateway.main.id
  description = "The ID of the Application Gateway"
}

output "appgw_public_ip" {
  value       = azurerm_public_ip.appgw.ip_address
  description = "The public IP address of the Application Gateway"
}

output "frontend_backend_pool_id" {
  # Get the ID of the FrontendBackendPool dynamically
  value       = one([for pool in azurerm_application_gateway.main.backend_address_pool : pool.id if pool.name == "FrontendBackendPool"])
  description = "The Frontend Backend Address Pool ID"
}

output "microservices_backend_pool_id" {
  # Get the ID of the MicroservicesBackendPool dynamically
  value       = one([for pool in azurerm_application_gateway.main.backend_address_pool : pool.id if pool.name == "MicroservicesBackendPool"])
  description = "The Microservices Backend Address Pool ID"
}
