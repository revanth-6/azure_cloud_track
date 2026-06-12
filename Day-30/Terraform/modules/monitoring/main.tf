# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-medishift-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "appinsights-medishift-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  application_type    = "web"
  tags                = var.tags
}

# Azure Monitor Workspace (Managed Prometheus)
resource "azurerm_monitor_workspace" "prometheus" {
  name                = "amw-medishift-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Azure Managed Grafana (Commented out due to API version 12 vs Provider version 9/10 conflict)
# resource "azurerm_dashboard_grafana" "grafana" {
#   name                              = "amg-medishift-${var.environment}"
#   resource_group_name               = var.resource_group_name
#   location                          = var.location
#   public_network_access_enabled     = true
#   sku                               = "Standard"
#   grafana_major_version             = 12
#   azure_monitor_workspace_integrations {
#     resource_id = azurerm_monitor_workspace.prometheus.id
#   }
# 
#   identity {
#     type = "SystemAssigned"
#   }
# 
#   tags = var.tags
# }

# Role Assignment: Grafana Identity needs "Monitoring Data Reader" on Prometheus (Monitor Workspace)
# resource "azurerm_role_assignment" "grafana_prometheus" {
#   scope                = azurerm_monitor_workspace.prometheus.id
#   role_definition_name = "Monitoring Data Reader"
#   principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
# }

# Role Assignment: Grafana Identity needs "Monitoring Reader" on the Resource Group to view Azure Monitor metrics
# resource "azurerm_role_assignment" "grafana_monitoring_reader" {
#   scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
#   role_definition_name = "Monitoring Reader"
#   principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
# }

# Metric Alerts
resource "azurerm_monitor_action_group" "ops" {
  name                = "ag-medishift-ops"
  resource_group_name = var.resource_group_name
  short_name          = "opsalert"

  email_receiver {
    name                    = "ops-lead"
    email_address           = "operations@medishift-prod.com"
    use_common_alert_schema = true
  }
}

# Alert: High CPU on AKS Node Pool (using Host VM metrics or AKS metrics)
resource "azurerm_monitor_metric_alert" "aks_cpu" {
  name                = "alert-aks-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Trigger alert if CPU utilization on AKS nodes exceeds 85%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

# Alert: High Memory on AKS Node Pool
resource "azurerm_monitor_metric_alert" "aks_mem" {
  name                = "alert-aks-high-memory"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Trigger alert if memory utilization on AKS nodes exceeds 90%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

# Alert: App Gateway Unhealthy Hosts
resource "azurerm_monitor_metric_alert" "appgw_unhealthy" {
  name                = "alert-appgw-unhealthy-hosts"
  resource_group_name = var.resource_group_name
  scopes              = [var.appgw_id]
  description         = "Trigger alert if Application Gateway reports unhealthy backend hosts"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

# Alert: PostgreSQL CPU Utilization
resource "azurerm_monitor_metric_alert" "postgres_cpu" {
  name                = "alert-postgres-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.postgres_id]
  description         = "Trigger alert if PostgreSQL CPU exceeds 85%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}
