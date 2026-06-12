variable "location" {
  type        = string
  description = "The Azure region for resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name."
}

variable "vnet_cidr" {
  type = list(string)
}

variable "subnet_appgw_cidr" {
  type = list(string)
}

variable "subnet_aks_cidr" {
  type = list(string)
}

variable "subnet_postgres_cidr" {
  type = list(string)
}

variable "subnet_private_endpoints_cidr" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}
