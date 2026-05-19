# Provider variables
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "dcf95f23-e23c-4b3d-a7ee-cd524c063f88"
}

# General variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "demo-rg"
}
variable "location" {
    description = "Azure Region"
    type        = string
    default     = "Central India"  
}
variable "tags" {
    description = "Common tags for all resources"
    type = map(string)
    default = {
        Environment = "demo"
        Project     = "terraform-learning"
}
}

# VNet variables
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "demo-vnet"
}
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Subnet variables
variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "demo-subnet"
}
variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

# NSG variables
variable "nsg_name" {
  description = "Name of the network security group"
  type        = string
  default     = "demo-nsg"
}

# Public IP variables
variable "public_ip_name" {
  description = "Name of the public IP address"
  type        = string
  default     = "demo-public-ip"
}
variable "public_ip_allocation_method" {
  description = "Allocation method for Public IP"
  type        = string
  default     = "Static"
}
variable "public_ip_sku" {
  description = "SKU for Public IP"
  type        = string
  default     = "Standard"
}

# NIC variables
variable "nic_name" {
  description = "Name of the network interface"
  type        = string
  default     = "demo-nic"
}
variable "ip_config_name" {
  description = "Name of the IP configuration"
  type        = string
  default     = "demo-ip-config"
}

# VM variables
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "demo-vm"
}
variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_D2s_v5"
}
variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}
variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  default     = "Revanth@562004"
  sensitive = true
}
variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
  default     = "ReadWrite"
}
variable "os_disk_storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Standard_LRS"
}
variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 30
}
variable "image_publisher" {
  description = "Publisher of the image"
  type        = string
  default     = "Canonical"
}
variable "image_offer" {
  description = "Offer of the image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}
variable "image_sku" {
  description = "SKU of the image"
  type        = string
  default     = "22_04-lts"
}
variable "image_version" {
  description = "Version of the image"
  type        = string
  default     = "latest"
}