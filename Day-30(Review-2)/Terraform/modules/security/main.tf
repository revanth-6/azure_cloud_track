data "azurerm_client_config" "current" {}

resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "postgres_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Azure Key Vault
resource "azurerm_key_vault" "vault" {
  name                          = "kv-medishift-${var.environment}-${random_string.kv_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true # Enterprise best practice: use Azure RBAC instead of access policies
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # Allow public access for deploying workstation, private endpoints remain active
  }

  tags = var.tags
}

# Key Vault Private DNS Zone
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "kv-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = var.vnet_id
}

# Key Vault Private Endpoint
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-keyvault"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_endpoints_id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.vault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdzg-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }

  tags = var.tags
}

# RBAC: Assign "Key Vault Administrator" to current deploying user/spn so we can write secrets
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC: Assign "Key Vault Secrets User" to AKS Workload Managed Identity so pods can read secrets
resource "azurerm_role_assignment" "aks_workload_kv_reader" {
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_workload_identity_principal_id
}

# Store application secrets in Key Vault (Requires depends_on role assignment to allow write)
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = "medishift_jwt_secret_key_2024"
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "db_user" {
  name         = "postgres-user"
  value        = var.postgres_admin_user
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "postgres-password"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "db_name" {
  name         = "postgres-db"
  value        = "medishift"
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "db_url" {
  name         = "database-url"
  value        = "postgresql://${var.postgres_admin_user}:${random_password.postgres_password.result}@${var.postgres_host}:${startswith(var.postgres_sku_name, "B_") ? "5432" : "6432"}/medishift?sslmode=require"
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

# Azure Container Registry Premium
resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_container_registry" "acr" {
  name                          = "acrmedishift${var.environment}${random_string.acr_suffix.result}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium" # Required for private endpoints and replication
  admin_enabled                 = false
  public_network_access_enabled = false

  dynamic "georeplications" {
    for_each = var.georeplication_enabled ? [1] : []
    content {
      location                = var.dr_location
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }

  tags = var.tags
}

# ACR Private DNS Zone
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.vnet_id
}

# ACR Private Endpoint
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_endpoints_id

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "pdzg-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = var.tags
}

# Azure Policy Initiative assignment: Microsoft Cloud Security Benchmark
# resource "azurerm_resource_group_policy_assignment" "mcsb" {
#   name                 = "policy-mcsb-prod"
#   resource_group_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
#   policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3dc3fb-24c6-4d7a-b183-49cae3142486"
#   description          = "Microsoft Cloud Security Benchmark Initiative Assignment for production baseline compliance"
#   display_name         = "Microsoft Cloud Security Benchmark (Prod)"
# }

# Azure Policy assignment: Require tags
# resource "azurerm_resource_group_policy_assignment" "require_tags" {
#   name                 = "policy-require-tags"
#   resource_group_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
#   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2a8d1131-155b-43d4-b749-ca33b5415e25"
#   description          = "Require tag Environment, Project, Owner on all resource groups"
#   display_name         = "Enforce Resource Group Tags (Prod)"
#   parameters = jsonencode({
#     tagName = {
#       value = "Environment"
#     }
#   })
# }
