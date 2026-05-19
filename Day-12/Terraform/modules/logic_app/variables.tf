variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "logic_app_name" {
  type = string
}

variable "servicebus_connection_string" {
  type      = string
  sensitive = true
}

variable "servicebus_topic_name" {
  type = string
}

variable "servicebus_namespace_endpoint" {
  description = "Service Bus namespace HTTPS endpoint"
  type        = string
}

variable "servicebus_sas_token" {
  description = "Service Bus SAS token for authentication"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}