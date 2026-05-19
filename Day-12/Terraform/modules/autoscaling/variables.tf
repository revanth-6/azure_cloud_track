variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "autoscale_name" {
  type = string
}

variable "vmss_id" {
  type = string
}

variable "min_instances" {
  type    = number
  default = 2
}

variable "max_instances" {
  type    = number
  default = 5
}

variable "default_instances" {
  type    = number
  default = 2
}

variable "scale_out_cpu_threshold" {
  type    = number
  default = 70
}

variable "scale_in_cpu_threshold" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}