resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_storage_account" "main" {
  name                     = "${var.storage_account_prefix}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "code" {
  name                  = "deployments"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Zip the MediShift codebase
data "archive_file" "medishift" {
  type        = "zip"
  source_dir  = "${path.root}/../MediShift_v1-main"
  output_path = "${path.root}/medishift.zip"
}

# Upload to storage account
resource "azurerm_storage_blob" "medishift" {
  name                   = "medishift.zip"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.code.name
  type                   = "Block"
  source                 = data.archive_file.medishift.output_path
}
