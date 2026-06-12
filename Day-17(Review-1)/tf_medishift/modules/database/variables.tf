variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "postgres_server_name" {
  type        = string
  description = "Name of the PostgreSQL Flexible Server"
}

variable "postgres_subnet_id" {
  type        = string
  description = "ID of the delegated PostgreSQL subnet"
}

variable "private_dns_zone_id" {
  type        = string
  description = "ID of the Private DNS Zone"
}

variable "postgres_admin_username" {
  type        = string
  description = "Admin username for PostgreSQL"
}

variable "postgres_admin_password" {
  type        = string
  description = "Admin password for PostgreSQL"
  sensitive   = true
}

variable "postgres_sku_name" {
  type        = string
  description = "PostgreSQL Flexible Server SKU"
  default     = "GP_Standard_D2s_v3"
}

variable "tags" {
  type    = map(string)
  default = {}
}
