resource "azurerm_postgresql_flexible_server" "main" {
  name                   = var.postgres_server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "15"
  delegated_subnet_id    = var.postgres_subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = var.postgres_sku_name

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "medishift" {
  name      = "medishift"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
