output "namespace_id" {
  value = azurerm_servicebus_namespace.sb_namespace.id
}

output "namespace_name" {
  value = azurerm_servicebus_namespace.sb_namespace.name
}

output "topic_id" {
  value = azurerm_servicebus_topic.sb_topic.id
}

output "topic_name" {
  value = azurerm_servicebus_topic.sb_topic.name
}

output "subscription_id" {
  value = azurerm_servicebus_subscription.sb_subscription.id
}

output "primary_connection_string" {
  value     = azurerm_servicebus_namespace.sb_namespace.default_primary_connection_string
  sensitive = true
}

output "primary_key" {
  value     = azurerm_servicebus_namespace.sb_namespace.default_primary_key
  sensitive = true
}

output "namespace_endpoint" {
  description = "Service Bus HTTPS endpoint"
  value       = "https://${azurerm_servicebus_namespace.sb_namespace.name}.servicebus.windows.net/"
}