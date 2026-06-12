resource "azurerm_web_application_firewall_policy" "main" {
  name                = "${var.appgw_name}-WAF-Policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.appgw_name}-PIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

locals {
  frontend_port_name             = "port-80"
  frontend_ip_config_name        = "appgw-frontend-ip"
  gateway_ip_config_name         = "appgw-gateway-ip-config"
  backend_http_setting_name      = "HTTPBackendSetting"
  
  frontend_backend_pool_name     = "FrontendBackendPool"
  microservices_backend_pool_name = "MicroservicesBackendPool"
  
  http_listener_name             = "medishift-http-listener"
  routing_rule_http_name         = "HTTPRoutingRule"
  url_path_map_name              = "medishift-url-path-map"
}

resource "azurerm_application_gateway" "main" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  firewall_policy_id = azurerm_web_application_firewall_policy.main.id

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_config_name
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name = local.frontend_backend_pool_name
  }

  backend_address_pool {
    name = local.microservices_backend_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_setting_name
    cookie_based_affinity = "Disabled"
    protocol              = "Http"
    port                  = 80
    request_timeout       = 20
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    # Omitted host_name to allow general path-based routing for all incoming hosts on port 80
    require_sni                    = false
  }

  # URL Path Map to route /* to Frontend and /api/* to Microservices
  url_path_map {
    name                               = local.url_path_map_name
    default_backend_address_pool_name   = local.frontend_backend_pool_name
    default_backend_http_settings_name  = local.backend_http_setting_name

    path_rule {
      name                       = "api-routing-rule"
      paths                      = ["/api/*"]
      backend_address_pool_name   = local.microservices_backend_pool_name
      backend_http_settings_name  = local.backend_http_setting_name
    }
  }

  # Inbound HTTP (80) -> Apply URL Path Map for path-based routing
  request_routing_rule {
    name               = local.routing_rule_http_name
    rule_type          = "PathBasedRouting"
    priority           = 100
    http_listener_name = local.http_listener_name
    url_path_map_name  = local.url_path_map_name
  }
}
