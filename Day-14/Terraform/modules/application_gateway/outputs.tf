output "appgw_public_ip" {
  description = "Add this IP as A record in GoDaddy for both subdomains"
  value       = azurerm_public_ip.appgw.ip_address
}

output "appgw_id" {
  value = azurerm_application_gateway.main.id
}

output "waf_policy_id" {
  value = azurerm_web_application_firewall_policy.main.id
}