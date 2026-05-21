variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "appgw_name" {
  type = string
}

variable "appgw_subnet_id" {
  type = string
}

variable "fitness_backend_ip" {
  description = "Private IP of VM-Fitness"
  type        = string
}

variable "organic_backend_ip" {
  description = "Private IP of VM-Organic"
  type        = string
}

variable "fitness_hostname" {
  description = "e.g. fitness.medishift.co.in"
  type        = string
}

variable "organic_hostname" {
  description = "e.g. organic.medishift.co.in"
  type        = string
}

variable "fitness_pfx_path" {
  description = "Local path to fitness.pfx"
  type        = string
}

variable "organic_pfx_path" {
  description = "Local path to organic.pfx"
  type        = string
}

variable "pfx_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}