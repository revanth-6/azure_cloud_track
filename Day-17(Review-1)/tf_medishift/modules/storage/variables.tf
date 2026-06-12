variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "storage_account_prefix" {
  type        = string
  description = "Prefix for the deployment storage account name"
  default     = "medishift"
}

variable "tags" {
  type    = map(string)
  default = {}
}
