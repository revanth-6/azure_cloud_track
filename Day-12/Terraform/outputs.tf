output "resource_group_name" {
  description = "Resource Group Name"
  value       = module.resource_group.resource_group_name
}

output "load_balancer_public_ip" {
  description = "Public IP of the Load Balancer"
  value       = module.load_balancer.public_ip_address
}

output "vmss_id" {
  description = "VMSS Resource ID"
  value       = module.vmss.vmss_id
}

output "vmss_name" {
  description = "VMSS Name"
  value       = module.vmss.vmss_name
}

output "servicebus_namespace_name" {
  description = "Service Bus Namespace"
  value       = module.service_bus.namespace_name
}

output "servicebus_topic_name" {
  description = "Service Bus Topic"
  value       = module.service_bus.topic_name
}

output "logic_app_webhook_url" {
  description = "Logic App Webhook URL (use in Action Group)"
  value       = module.logic_app.webhook_url
  sensitive   = true
}

output "app_url" {
  description = "Application URL via Load Balancer"
  value       = "http://${module.load_balancer.public_ip_address}"
}