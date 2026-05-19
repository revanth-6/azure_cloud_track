variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "lb_name" {
  type = string
}

variable "public_ip_name" {
  type = string
}

variable "app_port" {
  type    = number
  default = 5656
}

variable "tags" {
  type    = map(string)
  default = {}
}