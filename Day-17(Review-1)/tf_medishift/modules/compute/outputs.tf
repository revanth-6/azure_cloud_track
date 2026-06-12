output "microservices_private_ip" {
  value       = azurerm_linux_virtual_machine.microservices.private_ip_address
  description = "The private IP address of the Microservices VM"
}

output "frontend_vmss_id" {
  value       = azurerm_linux_virtual_machine_scale_set.frontend.id
  description = "The Resource ID of the Frontend VMSS"
}
