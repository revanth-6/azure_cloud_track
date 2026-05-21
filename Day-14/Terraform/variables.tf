variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}
variable "location" {
  description = "Azure region for all resources"
  type        = string
}
variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}
variable "vnet_address_space" {
  description = "Address space for VNet e.g. 10.0.0.0/16"
  type        = string
}
variable "fitness_subnet_name" {
  description = "Subnet name for Fitness VM"
  type        = string
}
variable "fitness_subnet_cidr" {
  description = "CIDR for Fitness subnet e.g. 10.0.1.0/24"
  type        = string
}
variable "organic_subnet_name" {
  description = "Subnet name for Organic VM"
  type        = string
}
variable "organic_subnet_cidr" {
  description = "CIDR for Organic subnet e.g. 10.0.2.0/24"
  type        = string
}
variable "appgw_subnet_name" {
  description = "Subnet name for Application Gateway (must be dedicated)"
  type        = string
}
variable "appgw_subnet_cidr" {
  description = "CIDR for AppGW subnet e.g. 10.0.3.0/24"
  type        = string
}

variable "nat_gateway_name" {
  description = "Name of NAT Gateway"
  type        = string
}

variable "fitness_vm_name" {
  description = "Name of Fitness Tracker VM"
  type        = string
}
variable "organic_vm_name" {
  description = "Name of Organic Ghee VM"
  type        = string
}
variable "vm_size" {
  description = "VM size - Standard_B2s recommended for MongoDB+Node+Nginx"
  type        = string
}
variable "admin_username" {
  description = "SSH admin username for both VMs"
  type        = string
}
variable "admin_password" {
  description = "SSH admin password for both VMs"
  type        = string
  sensitive   = true
}

variable "fitness_script_path" {
  description = "Relative path to fitness-tracker.sh script file"
  type        = string
}
variable "organic_script_path" {
  description = "Relative path to organic-ghee.sh script file"
  type        = string
}

variable "appgw_name" {
  description = "Name of the Application Gateway"
  type        = string
}
variable "fitness_hostname" {
  description = "Full hostname for Fitness app e.g. fitness.medishift.co.in"
  type        = string
}
variable "organic_hostname" {
  description = "Full hostname for Organic app e.g. organic.medishift.co.in"
  type        = string
}

variable "fitness_pfx_path" {
  description = "Local path to fitness.pfx certificate file"
  type        = string
}
variable "organic_pfx_path" {
  description = "Local path to organic.pfx certificate file"
  type        = string
}
variable "pfx_password" {
  description = "Password for .pfx files (set during openssl export)"
  type        = string
  sensitive   = true
}