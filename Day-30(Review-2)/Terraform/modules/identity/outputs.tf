output "aks_workload_identity_id" {
  value = azurerm_user_assigned_identity.aks_workload.id
}

output "aks_workload_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_workload.client_id
}

output "aks_workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_workload.principal_id
}

output "appgw_identity_id" {
  value = azurerm_user_assigned_identity.appgw.id
}

output "appgw_identity_client_id" {
  value = azurerm_user_assigned_identity.appgw.client_id
}

output "appgw_identity_principal_id" {
  value = azurerm_user_assigned_identity.appgw.principal_id
}
