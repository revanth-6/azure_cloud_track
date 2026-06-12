variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "vnet_name" {
  type        = string
  description = "Virtual Network name"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for VNet"
}

variable "appgw_subnet_name" {
  type        = string
  description = "Subnet name for App Gateway"
}

variable "appgw_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for App Gateway"
}

variable "frontend_subnet_name" {
  type        = string
  description = "Subnet name for Frontend VMSS"
}

variable "frontend_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for Frontend VMSS"
}

variable "microservices_subnet_name" {
  type        = string
  description = "Subnet name for Microservices VM"
}

variable "microservices_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for Microservices VM"
}

variable "postgres_subnet_name" {
  type        = string
  description = "Subnet name for PostgreSQL server"
}

variable "postgres_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for PostgreSQL server"
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for Bastion Host"
}

variable "nat_gateway_name" {
  type        = string
  description = "NAT Gateway name"
}

variable "tags" {
  type    = map(string)
  default = {}
}
