variable "location" {
  type        = string
  description = "The Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name."
}

variable "vnet_id" {
  type        = string
  description = "Virtual Network ID."
}

variable "subnet_postgres_id" {
  type        = string
  description = "Subnet ID delegated to PostgreSQL."
}

variable "postgres_version" {
  type = string
}

variable "postgres_sku_name" {
  type = string
}

variable "postgres_admin_user" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostic settings."
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}
