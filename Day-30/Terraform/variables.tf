variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID where resources will be deployed."
}

variable "primary_location" {
  type        = string
  default     = "eastus"
  description = "The primary Azure region for deployment."
}

variable "dr_location" {
  type        = string
  default     = "centralus"
  description = "The disaster recovery region (used for global geo-redundancy settings)."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-medishift-prod"
  description = "Name of the Resource Group."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to resources."
  default = {
    Environment = "Production"
    Project     = "MediShift"
    Owner       = "Platform-Team"
    CostCenter  = "Healthcare"
    ManagedBy   = "Terraform"
  }
}

variable "vnet_cidr" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "The address space for the virtual network."
}

variable "subnet_appgw_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "Subnet CIDR for Application Gateway."
}

variable "subnet_aks_cidr" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "Subnet CIDR for AKS Cluster nodes."
}

variable "subnet_postgres_cidr" {
  type        = list(string)
  default     = ["10.0.3.0/24"]
  description = "Subnet CIDR for PostgreSQL Flexible Server."
}

variable "subnet_private_endpoints_cidr" {
  type        = list(string)
  default     = ["10.0.4.0/24"]
  description = "Subnet CIDR for Private Endpoints."
}

variable "aks_vm_size" {
  type        = string
  default     = "Standard_D2s_v5"
  description = "VM size for AKS nodes."
}

variable "aks_system_node_count" {
  type        = number
  default     = 2
  description = "System node pool node count."
}

variable "aks_user_min_nodes" {
  type        = number
  default     = 2
  description = "Minimum number of user node pool nodes."
}

variable "aks_user_max_nodes" {
  type        = number
  default     = 5
  description = "Maximum number of user node pool nodes."
}

variable "postgres_sku_name" {
  type        = string
  default     = "MO_Standard_E2ds_v5" # Memory Optimized for production workloads
  description = "SKU for PostgreSQL Flexible Server."
}

variable "postgres_version" {
  type        = string
  default     = "15"
  description = "PostgreSQL Major version."
}

variable "postgres_admin_user" {
  type        = string
  default     = "medishift_admin"
  description = "Administrator username for PostgreSQL server."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "The environment suffix/context (e.g. dev, prod)."
}

variable "appgw_min_capacity" {
  type        = number
  default     = 1
  description = "Minimum capacity for Application Gateway autoscale."
}

variable "appgw_max_capacity" {
  type        = number
  default     = 10
  description = "Maximum capacity for Application Gateway autoscale."
}

variable "storage_replication_type" {
  type        = string
  default     = "ZRS"
  description = "Replication type for Azure storage account (e.g. LRS, ZRS)."
}

variable "georeplication_enabled" {
  type        = bool
  default     = true
  description = "Enable geo-replication for Azure Container Registry (ACR)."
}

