variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "servicebus_namespace_name" {
  type = string
}

variable "servicebus_topic_name" {
  type    = string
  default = "cpu-alert-topic"
}

variable "servicebus_subscription_name" {
  type    = string
  default = "email-alert-subscription"
}

variable "tags" {
  type    = map(string)
  default = {}
}