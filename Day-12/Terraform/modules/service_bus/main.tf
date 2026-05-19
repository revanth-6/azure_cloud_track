resource "azurerm_servicebus_namespace" "sb_namespace" {
  name                = var.servicebus_namespace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_servicebus_topic" "sb_topic" {
  name         = var.servicebus_topic_name
  namespace_id = azurerm_servicebus_namespace.sb_namespace.id

  max_size_in_megabytes = 1024

  default_message_ttl = "P1D"
}

resource "azurerm_servicebus_subscription" "sb_subscription" {
  name               = var.servicebus_subscription_name
  topic_id           = azurerm_servicebus_topic.sb_topic.id
  max_delivery_count = 10

  default_message_ttl = "P1D"

  dead_lettering_on_message_expiration = true
}