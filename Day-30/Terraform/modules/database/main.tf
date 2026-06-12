# Private DNS Zone for PostgreSQL Flexible Server
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "medishift-${var.environment}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "postgres-dns-link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = var.vnet_id
}

# PostgreSQL Flexible Server (Private VNet Integrated, Single Server for Free Trial)
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "db-medishift-${var.environment}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgres_version
  delegated_subnet_id    = var.subnet_postgres_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_admin_password

  sku_name   = var.postgres_sku_name
  storage_mb = 32768

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false # Opt out of public access to avoid subnet conflicts

  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_link]
}

# Database Instance
resource "azurerm_postgresql_flexible_server_database" "medishift" {
  name      = "medishift"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Enable Native PgBouncer
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer" {
  count     = startswith(var.postgres_sku_name, "B_") ? 0 : 1
  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "true"
}

# Diagnostic Settings for auditing database health
resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "ds-postgres"
  target_resource_id         = azurerm_postgresql_flexible_server.postgres.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
