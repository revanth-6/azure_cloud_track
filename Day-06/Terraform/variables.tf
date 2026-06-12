variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "myRG"
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
  default     = "Central India"
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {
    environment = "dev"
    project     = "myProject"
  }
}


variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "myVNet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}


variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
  default     = "PublicSubnet"
}

variable "public_subnet_prefix" {
  description = "Address prefix for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
  default     = "PrivateSubnet"
}

variable "private_subnet_prefix" {
  description = "Address prefix for the private subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "appgw_subnet_name" {
  description = "Name of the Application Gateway subnet"
  type        = string
  default     = "AppGwSubnet"
}

variable "appgw_subnet_prefix" {
  description = "Address prefix for the Application Gateway subnet"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}


variable "public_vm_name" {
  description = "Name of the public VM"
  type        = string
  default     = "PublicVM"
}

variable "private_vm_name" {
  description = "Name of the private VM"
  type        = string
  default     = "PrivateVM"
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  default     = "Revanth@562004"
}

variable "vm_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "vm_image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "22_04-lts"
}

variable "vm_image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}


variable "node_app_port" {
  description = "Port on which the Node.js app will run"
  type        = number
  default     = 5656
}

variable "nginx_port" {
  description = "Port on which Nginx will listen"
  type        = number
  default     = 80
}


variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
  default     = "myNatGateway"
}

variable "nat_idle_timeout" {
  description = "Idle timeout for the NAT Gateway in minutes"
  type        = number
  default     = 10
}

variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
  default     = "myAppGateway"
}

variable "app_gateway_sku" {
  description = "SKU of the Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_sku_size" {
  description = "Size of the Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  description = "Tier of the Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  description = "Capacity of the Application Gateway"
  type        = number
  default     = 1
}