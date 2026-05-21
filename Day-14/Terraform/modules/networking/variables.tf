variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "fitness_subnet_name" {
  type = string
}

variable "fitness_subnet_cidr" {
  type = string
}

variable "organic_subnet_name" {
  type = string
}

variable "organic_subnet_cidr" {
  type = string
}

variable "appgw_subnet_name" {
  type = string
}

variable "appgw_subnet_cidr" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}