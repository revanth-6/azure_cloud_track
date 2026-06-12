variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "Central India"
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

# Networking
variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "appgw_subnet_name" {
  description = "Subnet name for App Gateway"
  type        = string
  default     = "AppGateway-Subnet"
}

variable "appgw_subnet_cidr" {
  description = "Subnet CIDR for App Gateway"
  type        = string
  default     = "10.0.1.0/24"
}

variable "frontend_subnet_name" {
  description = "Subnet name for Frontend VMSS"
  type        = string
  default     = "Frontend-Subnet"
}

variable "frontend_subnet_cidr" {
  description = "Subnet CIDR for Frontend VMSS"
  type        = string
  default     = "10.0.2.0/24"
}

variable "microservices_subnet_name" {
  description = "Subnet name for Microservices VM"
  type        = string
  default     = "Microservices-Subnet"
}

variable "microservices_subnet_cidr" {
  description = "Subnet CIDR for Microservices VM"
  type        = string
  default     = "10.0.3.0/24"
}

variable "postgres_subnet_name" {
  description = "Subnet name for PostgreSQL server (Delegated)"
  type        = string
  default     = "AzurePostgres-Subnet"
}

variable "postgres_subnet_cidr" {
  description = "Subnet CIDR for PostgreSQL server"
  type        = string
  default     = "10.0.4.0/24"
}

variable "bastion_subnet_cidr" {
  description = "Subnet CIDR for Bastion Host"
  type        = string
  default     = "10.0.5.0/24"
}

variable "nat_gateway_name" {
  description = "Name of NAT Gateway"
  type        = string
}

# Identity
variable "identity_name" {
  description = "Name of the User-Assigned Managed Identity"
  type        = string
  default     = "medishift-identity"
}

# Database
variable "postgres_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  type        = string
}

variable "postgres_admin_username" {
  description = "Administrator login for PostgreSQL"
  type        = string
  default     = "medishift"
}

variable "postgres_admin_password" {
  description = "Administrator password for PostgreSQL"
  type        = string
  sensitive   = true
}

variable "postgres_sku_name" {
  description = "PostgreSQL Flexible Server SKU"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

# Compute
variable "microservices_vm_name" {
  description = "Name of Microservices VM"
  type        = string
  default     = "VM-Microservices"
}

variable "frontend_vmss_name" {
  description = "Name of Frontend VMSS"
  type        = string
  default     = "VMSS-Frontend"
}

variable "vm_size" {
  description = "Compute VM size SKU (DC-series constrained)"
  type        = string
  default     = "Standard_DC1ds_v3"
}

variable "admin_username" {
  description = "SSH admin username for VM/VMSS"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "SSH admin password for VM/VMSS"
  type        = string
  sensitive   = true
}

variable "frontend_instances_count" {
  description = "Number of instances in Frontend VMSS"
  type        = number
  default     = 2
}

# App Gateway
variable "appgw_name" {
  description = "Name of Application Gateway"
  type        = string
}

variable "hostname" {
  description = "Hostname for HTTP listener e.g. medishift.co.in"
  type        = string
}
