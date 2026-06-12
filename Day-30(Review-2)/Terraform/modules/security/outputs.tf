output "key_vault_id" {
  value = azurerm_key_vault.vault.id
}

output "key_vault_name" {
  value = azurerm_key_vault.vault.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.vault.vault_uri
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "postgres_password" {
  value     = random_password.postgres_password.result
  sensitive = true
}
