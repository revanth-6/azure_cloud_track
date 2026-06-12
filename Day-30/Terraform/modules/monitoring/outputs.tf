output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.workspace.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.workspace.name
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.app_insights.instrumentation_key
  sensitive = true
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.app_insights.connection_string
  sensitive = true
}

output "monitor_workspace_id" {
  value = azurerm_monitor_workspace.prometheus.id
}

# output "grafana_endpoint" {
#   value = azurerm_dashboard_grafana.grafana.endpoint
# }
