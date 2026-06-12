variable "location" {
  type        = string
  description = "The Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name."
}

variable "subnet_appgw_id" {
  type        = string
  description = "Subnet ID for Application Gateway."
}

variable "subnet_aks_cidr" {
  type        = list(string)
  description = "Subnet CIDR for AKS."
}

variable "appgw_identity_id" {
  type        = string
  description = "User Assigned Managed Identity resource ID for the App Gateway."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostic settings."
}

variable "ssl_cert_data" {
  type        = string
  description = "Base64 encoded PFX certificate file data."
  sensitive   = true
}

variable "ssl_cert_password" {
  type        = string
  description = "Password for the PFX certificate."
  sensitive   = true
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}

variable "appgw_min_capacity" {
  type        = number
  description = "Minimum autoscale capacity."
}

variable "appgw_max_capacity" {
  type        = number
  description = "Maximum autoscale capacity."
}
