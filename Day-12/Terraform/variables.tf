variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}
variable "location" {
  description = "Azure Region"
  type        = string
  default     = "Central India"
}
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}
variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}
variable "subnet_name" {
  description = "Name of the Subnet"
  type        = string
}
variable "subnet_address_prefix" {
  description = "Address prefix for Subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "nsg_name" {
  description = "Name of the Network Security Group"
  type        = string
}
variable "lb_name" {
  description = "Name of the Load Balancer"
  type        = string
}
variable "public_ip_name" {
  description = "Name of the Public IP"
  type        = string
}
variable "app_port" {
  description = "Application port"
  type        = number
  default     = 5656
}

variable "vmss_name" {
  description = "Name of the VMSS"
  type        = string
}
variable "vm_sku" {
  description = "VM Size/SKU"
  type        = string
  default     = "Standard_B2s"
}
variable "instance_count" {
  description = "Initial number of VM instances"
  type        = number
  default     = 2
}
variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}
variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}
variable "os_disk_size_gb" {
  description = "OS Disk size in GB"
  type        = number
  default     = 30
}

variable "autoscale_name" {
  description = "Name of the autoscale setting"
  type        = string
}
variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}
variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 5
}
variable "default_instances" {
  description = "Default number of instances"
  type        = number
  default     = 2
}
variable "scale_out_cpu_threshold" {
  description = "CPU % threshold to scale out"
  type        = number
  default     = 70
}
variable "scale_in_cpu_threshold" {
  description = "CPU % threshold to scale in"
  type        = number
  default     = 30
}

variable "servicebus_namespace_name" {
  description = "Service Bus Namespace name (must be globally unique)"
  type        = string
}
variable "servicebus_topic_name" {
  description = "Service Bus Topic name"
  type        = string
  default     = "cpu-alert-topic"
}
variable "servicebus_subscription_name" {
  description = "Service Bus Subscription name"
  type        = string
  default     = "email-alert-subscription"
}

variable "logic_app_name" {
  description = "Name of the Logic App"
  type        = string
}

variable "action_group_name" {
  description = "Name of the Monitor Action Group"
  type        = string
}
variable "alert_rule_name" {
  description = "Name of the Alert Rule"
  type        = string
}
variable "alert_email" {
  description = "Email address to receive alerts"
  type        = string
}