output "fitness_vm_private_ip" {
  description = "Private IP of VM-Fitness — used as AppGW backend target"
  value       = azurerm_network_interface.fitness.private_ip_address
}

output "organic_vm_private_ip" {
  description = "Private IP of VM-Organic — used as AppGW backend target"
  value       = azurerm_network_interface.organic.private_ip_address
}

output "fitness_vm_id" {
  value = azurerm_linux_virtual_machine.fitness.id
}

output "organic_vm_id" {
  value = azurerm_linux_virtual_machine.organic.id
}