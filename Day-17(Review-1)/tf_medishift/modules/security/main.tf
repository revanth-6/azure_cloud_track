resource "azurerm_user_assigned_identity" "medishift" {
  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "storage_reader" {
  scope                = var.storage_container_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.medishift.principal_id
}
