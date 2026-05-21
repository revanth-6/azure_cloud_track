variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "nat_gateway_name" {
  type = string
}

variable "fitness_subnet_id" {
  type = string
}

variable "organic_subnet_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}