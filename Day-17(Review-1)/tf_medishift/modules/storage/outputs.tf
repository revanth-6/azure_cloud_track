output "storage_account_name" {
  value       = azurerm_storage_account.main.name
  description = "The storage account name"
}

output "storage_container_id" {
  value       = azurerm_storage_container.code.resource_manager_id
  description = "The Resource Manager ID of the storage container"
}

output "storage_container_name" {
  value       = azurerm_storage_container.code.name
  description = "The storage container name"
}

output "blob_name" {
  value       = azurerm_storage_blob.medishift.name
  description = "The name of the uploaded blob"
}

output "blob_url" {
  value       = azurerm_storage_blob.medishift.url
  description = "The URL of the uploaded blob"
}
