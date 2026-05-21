variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "fitness_vm_name" {
  type = string
}

variable "organic_vm_name" {
  type = string
}

variable "vm_size" {
  description = "Standard_B2s recommended for MongoDB + Node.js + Nginx"
  type        = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "fitness_subnet_id" {
  type = string
}

variable "organic_subnet_id" {
  type = string
}

variable "fitness_script_path" {
  description = "Path to fitness-tracker.sh bootstrap script"
  type        = string
}

variable "organic_script_path" {
  description = "Path to organic-ghee.sh bootstrap script"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}