output "identity_id" {
  value       = azurerm_user_assigned_identity.medishift.id
  description = "The Resource ID of the User-Assigned Managed Identity"
}

output "identity_client_id" {
  value       = azurerm_user_assigned_identity.medishift.client_id
  description = "The Client ID of the User-Assigned Managed Identity"
}

output "identity_principal_id" {
  value       = azurerm_user_assigned_identity.medishift.principal_id
  description = "The Principal ID of the User-Assigned Managed Identity"
}
