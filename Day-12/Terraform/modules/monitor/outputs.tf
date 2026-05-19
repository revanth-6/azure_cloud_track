output "action_group_id" {
  value = azurerm_monitor_action_group.action_group.id
}

output "action_group_name" {
  value = azurerm_monitor_action_group.action_group.name
}

output "high_cpu_alert_id" {
  value = azurerm_monitor_metric_alert.high_cpu_alert.id
}