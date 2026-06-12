variable "location" {
  type        = string
  description = "The Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name."
}

variable "subnet_aks_id" {
  type        = string
  description = "Subnet ID for AKS nodes."
}

variable "aks_vm_size" {
  type = string
}

variable "aks_system_node_count" {
  type = number
}

variable "aks_user_min_nodes" {
  type = number
}

variable "aks_user_max_nodes" {
  type = number
}

variable "acr_id" {
  type        = string
  description = "Resource ID of the Azure Container Registry."
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
