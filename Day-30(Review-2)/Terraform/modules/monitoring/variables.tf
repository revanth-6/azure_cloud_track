variable "location" {
  type        = string
  description = "The Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name."
}

variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID."
}

variable "aks_cluster_id" {
  type        = string
  description = "The Resource ID of the AKS cluster."
}

variable "appgw_id" {
  type        = string
  description = "The Resource ID of the Application Gateway."
}

variable "postgres_id" {
  type        = string
  description = "The Resource ID of the PostgreSQL Flexible Server."
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}
