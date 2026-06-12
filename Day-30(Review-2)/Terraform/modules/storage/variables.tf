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

variable "subnet_private_endpoints_id" {
  type        = string
  description = "Subnet ID for Private Endpoints."
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}

variable "storage_replication_type" {
  type        = string
  description = "The storage replication type (e.g. LRS, ZRS)."
}
