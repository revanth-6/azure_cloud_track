resource "azurerm_logic_app_workflow" "logic_app" {
  name                = var.logic_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_logic_app_trigger_http_request" "http_trigger" {
  name         = "http-trigger"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id

  schema = jsonencode({
    type = "object"
    properties = {
      schemaId = {
        type = "string"
      }
      data = {
        type = "object"
        properties = {
          essentials = {
            type = "object"
            properties = {
              alertId = {
                type = "string"
              }
              alertRule = {
                type = "string"
              }
              severity = {
                type = "string"
              }
              signalType = {
                type = "string"
              }
              monitorCondition = {
                type = "string"
              }
              monitoringService = {
                type = "string"
              }
              firedDateTime = {
                type = "string"
              }
              description = {
                type = "string"
              }
            }
          }
        }
      }
    }
  })
}

resource "azurerm_logic_app_action_custom" "send_to_servicebus" {
  name         = "Send-To-ServiceBus"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id

  body = jsonencode({
    type = "Http"
    inputs = {
      method = "POST"
      uri    = "${var.servicebus_namespace_endpoint}${var.servicebus_topic_name}/messages"
      headers = {
        "Content-Type"  = "application/json"
        "Authorization" = var.servicebus_sas_token
      }
      body = "@triggerBody()"
    }
    runAfter = {}
  })

  depends_on = [
    azurerm_logic_app_trigger_http_request.http_trigger
  ]
}