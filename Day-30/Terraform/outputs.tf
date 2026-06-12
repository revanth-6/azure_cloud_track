output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the Resource Group."
}

# output "frontdoor_url" {
#   value       = module.frontdoor.endpoint_hostname
#   description = "The global entrypoint URL provided by Azure Front Door."
# }

output "appgw_public_ip" {
  value       = module.appgateway.public_ip_address
  description = "The public IP of the regional Azure Application Gateway."
}

output "postgres_fqdn" {
  value       = module.database.postgres_fqdn
  description = "The FQDN of the PostgreSQL Flexible Server."
}

output "postgres_connection_string_pgbouncer" {
  value       = "postgresql://${var.postgres_admin_user}:[PASSWORD]@${module.database.postgres_fqdn}:${startswith(var.postgres_sku_name, "B_") ? "5432" : "6432"}/medishift?sslmode=require"
  description = "Connection string utilizing native PgBouncer port (6432) or standard fallback port (5432) when burstable."
  sensitive   = true
}

output "key_vault_uri" {
  value       = module.security.key_vault_uri
  description = "The URI of the Azure Key Vault."
}

output "aks_oidc_issuer_url" {
  value       = module.aks.oidc_issuer_url
  description = "The OIDC issuer URL of the AKS cluster for Workload Identity."
}

output "aks_cluster_name" {
  value       = module.aks.cluster_name
  description = "The name of the AKS cluster."
}

output "acr_login_server" {
  value       = module.security.acr_login_server
  description = "The login server of the Azure Container Registry."
}
