variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "microservices_vm_name" {
  type        = string
  description = "Name of the Microservices VM"
}

variable "frontend_vmss_name" {
  type        = string
  description = "Name of the Frontend VMSS"
}

variable "vm_size" {
  type        = string
  description = "Azure VM Size SKU"
  default     = "Standard_DC1ds_v3"
}

variable "admin_username" {
  type        = string
  description = "VM Administrator username"
}

variable "admin_password" {
  type        = string
  description = "VM Administrator password"
  sensitive   = true
}

variable "frontend_subnet_id" {
  type        = string
  description = "Subnet ID for Frontend VMSS"
}

variable "microservices_subnet_id" {
  type        = string
  description = "Subnet ID for Microservices VM"
}

variable "identity_id" {
  type        = string
  description = "Resource ID of the User-Assigned Managed Identity"
}

variable "identity_client_id" {
  type        = string
  description = "Client ID of the User-Assigned Managed Identity"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for source code"
}

variable "storage_container_name" {
  type        = string
  description = "Storage container name for source code"
}

variable "blob_name" {
  type        = string
  description = "Blob name for source code zip package"
}

variable "db_host" {
  type        = string
  description = "Database Host FQDN"
}

variable "db_user" {
  type        = string
  description = "Database admin user"
}

variable "db_pass" {
  type        = string
  description = "Database admin password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "medishift"
}

variable "jwt_secret" {
  type        = string
  description = "JWT shared secret for microservices"
}

variable "frontend_instances_count" {
  type        = number
  description = "Number of VM instances in Frontend VMSS"
  default     = 2
}

variable "appgw_frontend_backend_pool_id" {
  type        = string
  description = "Application Gateway Frontend Backend address pool ID"
}

variable "appgw_microservices_backend_pool_id" {
  type        = string
  description = "Application Gateway Microservices Backend address pool ID"
}

variable "tags" {
  type    = map(string)
  default = {}
}
