# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.demo_rg.name
}
output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.demo_rg.location
}

# VNet Outputs
output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.demo_vnet.name
}
output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.demo_vnet.id
}
output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.demo_vnet.address_space
}

# Subnet Outputs
output "subnet_name" {
  description = "Name of the subnet"
  value       = azurerm_subnet.demo_subnet.name
}
output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.demo_subnet.id
}
output "subnet_address_prefixes" {
  description = "Address prefixes of the subnet"
  value       = azurerm_subnet.demo_subnet.address_prefixes
}

# NSG Outputs
output "nsg_name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.demo_nsg.name
}
output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.demo_nsg.id
}

# Public IP Outputs
output "public_ip_name" {
  description = "Name of the public IP"
  value       = azurerm_public_ip.demo_public_ip.name
}
output "public_ip_address" {
  description = "The actual public IP address assigned"
  value       = azurerm_public_ip.demo_public_ip.ip_address
}

# NIC Outputs
output "nic_name" {
  description = "Name of the network interface"
  value       = azurerm_network_interface.demo_nic.name
}
output "nic_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.demo_nic.id
}
output "nic_private_ip" {
  description = "Private IP address of the NIC"
  value       = azurerm_network_interface.demo_nic.private_ip_address
}

# VM Outputs
output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.demo_vm.name
}
output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.demo_vm.id
}
output "vm_size" {
  description = "Size of the virtual machine"
  value       = azurerm_linux_virtual_machine.demo_vm.size
}
output "admin_username" {
  description = "Admin username of the virtual machine"
  value       = azurerm_linux_virtual_machine.demo_vm.admin_username
}

# SSH Connection Command (Very Useful!)
output "ssh_connection_command" {
  description = "Command to SSH into the virtual machine"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.demo_public_ip.ip_address}"
}