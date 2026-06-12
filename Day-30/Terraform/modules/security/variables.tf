variable "location" {
  type        = string
  description = "The Azure region."
}

variable "dr_location" {
  type        = string
  description = "The Azure disaster recovery region."
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

variable "aks_workload_identity_principal_id" {
  type        = string
  description = "Principal ID of the AKS workload managed identity."
}

variable "postgres_admin_user" {
  type = string
}

variable "postgres_host" {
  type        = string
  description = "PostgreSQL FQDN (host) used to compile database URL."
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}

variable "georeplication_enabled" {
  type        = bool
  description = "Enable georeplication for ACR (requires Premium SKU)."
}

variable "postgres_sku_name" {
  type        = string
  description = "PostgreSQL SKU name to determine if PgBouncer is supported."
  default     = "B_Standard_B2s"
}
