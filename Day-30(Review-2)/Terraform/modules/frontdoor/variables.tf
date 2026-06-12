variable "resource_group_name" {
  type        = string
  description = "Resource Group name."
}

variable "appgw_fqdn" {
  type        = string
  description = "FQDN of the Application Gateway backend origin."
}

variable "tags" {
  type = map(string)
}

variable "environment" {
  type        = string
  description = "The environment suffix/context."
}
