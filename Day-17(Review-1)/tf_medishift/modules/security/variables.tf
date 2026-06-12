variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "identity_name" {
  type        = string
  description = "Name of the User-Assigned Managed Identity"
}

variable "storage_container_id" {
  type        = string
  description = "Scope ID of the storage container for role assignment"
}

variable "tags" {
  type    = map(string)
  default = {}
}
