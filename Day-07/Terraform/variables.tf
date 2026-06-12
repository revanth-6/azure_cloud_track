variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default = "FitTrack-RG"
}

variable "vm1_location" {
  description = "Location for VM-1 (Frontend + Backend)"
  type        = string
  default     = "centralindia"
}

variable "vm2_location" {
  description = "Location for VM-2 (MongoDB Database)"
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the virtual machines"
  type        = string
  default     = "Revanth@562004"
  sensitive   = true
}

variable "vnet1_address_space" {
  description = "Address space for VNet-1 (Frontend + Backend)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vnet2_address_space" {
  description = "Address space for VNet-2 (MongoDB Database)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet1_prefix" {
  description = "Subnet prefix for Subnet-1 (Frontend + Backend)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet2_prefix" {
  description = "Subnet prefix for Subnet-2 (MongoDB Database)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "github_repo" {
  description = "GitHub repository URL for the application code"
  type        = string
  default     = "https://github.com/Msocial123/Fitness_Tracker.git"
}
