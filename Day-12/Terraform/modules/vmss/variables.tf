variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vmss_name" {
  type = string
}

variable "vm_sku" {
  type    = string
  default = "Standard_B2s"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "subnet_id" {
  type = string
}

variable "lb_backend_pool_id" {
  type = string
}

variable "lb_probe_id" {
  type = string
}

variable "lb_rule_id" {
  description = "LB Rule ID — VMSS must wait for this to be active before starting"
  type        = string
}

variable "os_disk_size_gb" {
  type    = number
  default = 30
}

variable "bootstrap_script_base64" {
  description = "Base64 encoded bootstrap script"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}