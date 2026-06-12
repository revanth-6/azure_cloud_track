resource "azurerm_user_assigned_identity" "aks_workload" {
  name                = "id-medishift-aks-workload"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "aks_workload_fed" {
  name                = "fed-medishift-aks-workload"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.aks_workload.id
  subject             = "system:serviceaccount:medishift-${var.environment}:medishift-sa"
}

resource "azurerm_user_assigned_identity" "appgw" {
  name                = "id-medishift-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
