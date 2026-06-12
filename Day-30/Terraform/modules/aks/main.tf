# Private AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-medishift-${var.environment}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = "medishift-aks-${var.environment}"
  private_cluster_enabled = false
  # private_dns_zone_id     = "System" # Azure will manage the private DNS zone for the cluster

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = "systempool"
    vm_size              = var.aks_vm_size
    node_count           = var.aks_system_node_count
    vnet_subnet_id       = var.subnet_aks_id
    type                 = "VirtualMachineScaleSets"
    os_disk_size_gb      = 128
    orchestrator_version = "1.34.7"

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure" # Enables Kubernetes Network Policies
    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Ingest metrics into Managed Prometheus (Monitor Workspace)
  monitor_metrics {}

  # Ingest logs/metrics into Log Analytics
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }



  tags = var.tags
}

# User Node Pool with Autoscaler commented out to fit within 4 vCPU subscription quota
# resource "azurerm_kubernetes_cluster_node_pool" "user" {
#   name                  = "userpool"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
#   vm_size               = var.aks_vm_size
#   vnet_subnet_id        = var.subnet_aks_id
#   orchestrator_version  = "1.34.7"
# 
#   enable_auto_scaling = true
#   min_count           = var.aks_user_min_nodes
#   max_count           = var.aks_user_max_nodes
#   node_count          = var.aks_user_min_nodes
# 
#   mode = "User"
# 
#   lifecycle {
#     ignore_changes = [
#       node_count
#     ]
#   }
# 
#   tags = var.tags
# }

# Role Assignment: Allow AKS Kubelet Identity to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Diagnostic settings for the Kubernetes cluster control plane
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "ds-aks"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Role Assignment: Allow AKS Cluster Identity to manage networking in the AKS subnet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.subnet_aks_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Role Assignment: Allow AKS Kubelet Identity to manage networking in the AKS subnet
resource "azurerm_role_assignment" "aks_kubelet_network_contributor" {
  scope                = var.subnet_aks_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
