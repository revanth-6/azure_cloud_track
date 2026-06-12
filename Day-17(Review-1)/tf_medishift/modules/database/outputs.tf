output "postgres_server_id" {
  value       = azurerm_postgresql_flexible_server.main.id
  description = "The PostgreSQL server ID"
}

output "postgres_server_fqdn" {
  value       = azurerm_postgresql_flexible_server.main.fqdn
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
}

output "postgres_database_name" {
  value       = azurerm_postgresql_flexible_server_database.medishift.name
  description = "The PostgreSQL database name"
}
