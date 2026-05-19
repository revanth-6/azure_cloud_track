output "lb_id" {
  value = azurerm_lb.lb.id
}

output "lb_name" {
  value = azurerm_lb.lb.name
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}

output "probe_id" {
  value = azurerm_lb_probe.health_probe.id
}

output "lb_rule_id" {
  description = "LB Rule ID — pass to VMSS so it waits for rule to be active"
  value       = azurerm_lb_rule.lb_rule.id
}

output "public_ip_address" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "frontend_config_name" {
  value = "LB-Frontend"
}