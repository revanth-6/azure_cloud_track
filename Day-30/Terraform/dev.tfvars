# Azure Configuration
subscription_id  = "f1808c66-ab07-46b3-bb93-06c6f2f406dc"
primary_location = "centralus"
dr_location      = "eastus2"
environment      = "dev"

# Resource Group Name
resource_group_name = "rg-medishift-dev"

# Network CIDRs
vnet_cidr                     = ["10.0.0.0/16"]
subnet_appgw_cidr             = ["10.0.1.0/24"]
subnet_aks_cidr               = ["10.0.2.0/24"]
subnet_postgres_cidr          = ["10.0.3.0/24"]
subnet_private_endpoints_cidr = ["10.0.4.0/24"]

# AKS Node Sizing (Cost Optimized for Dev)
aks_vm_size           = "Standard_D2s_v4"
aks_system_node_count = 2
aks_user_min_nodes    = 1
aks_user_max_nodes    = 2

# PostgreSQL Sizing & Version (Burstable for Dev)
postgres_sku_name   = "B_Standard_B2s"
postgres_version    = "15"
postgres_admin_user = "medishift_admin"

# App Gateway Capacity Limits
appgw_min_capacity = 1
appgw_max_capacity = 2

# Storage Replication Tier (Locally Redundant for Dev)
storage_replication_type = "LRS"

# ACR Georeplication (Disabled for Dev to avoid Premium cost duplication)
georeplication_enabled = false

# Tagging for Cost Tracking
tags = {
  Environment = "Development"
  Project     = "MediShift"
  Owner       = "Platform-Team"
  CostCenter  = "Healthcare-Dev"
  ManagedBy   = "Terraform"
}
