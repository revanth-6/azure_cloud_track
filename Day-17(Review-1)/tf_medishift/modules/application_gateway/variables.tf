variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "appgw_name" {
  type        = string
  description = "Name of the Application Gateway"
}

variable "appgw_subnet_id" {
  type        = string
  description = "ID of the dedicated App Gateway subnet"
}

variable "tags" {
  type    = map(string)
  default = {}
}
