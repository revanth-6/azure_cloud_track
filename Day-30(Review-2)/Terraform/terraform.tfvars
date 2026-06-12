# Azure Configuration
subscription_id  = "f1808c66-ab07-46b3-bb93-06c6f2f406dc"
primary_location = "centralus"
dr_location      = "eastus2"

# VNet IP Addressing
vnet_cidr                     = ["10.0.0.0/16"]
subnet_appgw_cidr             = ["10.0.1.0/24"]
subnet_aks_cidr               = ["10.0.2.0/24"]
subnet_postgres_cidr          = ["10.0.3.0/24"]
subnet_private_endpoints_cidr = ["10.0.4.0/24"]

# AKS Node Sizing
aks_vm_size           = "Standard_D2s_v4"
aks_system_node_count = 2
aks_user_min_nodes    = 2
aks_user_max_nodes    = 5

# PostgreSQL Sizing & Version
postgres_sku_name   = "MO_Standard_E2ds_v5"
postgres_version    = "15"
postgres_admin_user = "medishift_admin"
