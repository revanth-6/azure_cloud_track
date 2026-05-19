variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_id" {
  description = "Resource Group ID — needed for activity log alert scope"
  type        = string
}

variable "vmss_id" {
  type = string
}

variable "action_group_name" {
  type = string
}

variable "alert_rule_name" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "logic_app_webhook_url" {
  type      = string
  sensitive = true
}

variable "cpu_threshold" {
  type    = number
  default = 70
}

variable "tags" {
  type    = map(string)
  default = {}
}