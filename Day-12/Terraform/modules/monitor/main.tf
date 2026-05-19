resource "azurerm_monitor_action_group" "action_group" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "VMSSAlerts"
  tags                = var.tags

  email_receiver {
    name                    = "DirectEmailAlert"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  webhook_receiver {
    name                    = "LogicAppWebhook"
    service_uri             = var.logic_app_webhook_url
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu_alert" {
  name                = var.alert_rule_name
  resource_group_name = var.resource_group_name
  scopes              = [var.vmss_id]
  description         = "Alert when VMSS CPU exceeds ${var.cpu_threshold}%"
  severity            = 2
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

resource "azurerm_monitor_activity_log_alert" "scale_out_alert" {
  name                = "ScaleOut-Notification"
  resource_group_name = var.resource_group_name
  #location            = "global"
  scopes              = [var.resource_group_id]
  description         = "Notifies when VMSS autoscale scales out"
  tags                = var.tags

  criteria {
    category       = "Autoscale"
    operation_name = "Microsoft.Insights/AutoscaleSettings/Scaleup/Action"

    resource_id    = var.vmss_id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}