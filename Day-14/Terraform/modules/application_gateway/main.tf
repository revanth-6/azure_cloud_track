resource "azurerm_web_application_firewall_policy" "main" {
  name                = "HostRouting-WAF"
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
  name                = "AppGW-PublicIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
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

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  backend_address_pool {
    name         = "FitnessBackendPool"
    ip_addresses = [var.fitness_backend_ip]
  }

  backend_address_pool {
    name         = "OrganicBackendPool"
    ip_addresses = [var.organic_backend_ip]
  }

  backend_http_settings {
    name                  = "HTTPBackendSetting"
    cookie_based_affinity = "Disabled"
    protocol              = "Http"
    port                  = 80
    request_timeout       = 20
  }

  ssl_certificate {
    name     = "fitness-cert"
    data     = filebase64(var.fitness_pfx_path)
    password = var.pfx_password
  }

  ssl_certificate {
    name     = "organic-cert"
    data     = filebase64(var.organic_pfx_path)
    password = var.pfx_password
  }

  http_listener {
    name                           = "FitnessHTTPListener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.fitness_hostname
    require_sni                    = false
  }

  http_listener {
    name                           = "OrganicHTTPListener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.organic_hostname
    require_sni                    = false
  }

  http_listener {
    name                           = "FitnessHTTPSListener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-443"
    protocol                       = "Https"
    host_name                      = var.fitness_hostname
    ssl_certificate_name           = "fitness-cert"
    require_sni                    = true
  }

  http_listener {
    name                           = "OrganicHTTPSListener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-443"
    protocol                       = "Https"
    host_name                      = var.organic_hostname
    ssl_certificate_name           = "organic-cert"
    require_sni                    = true
  }

  redirect_configuration {
    name                 = "FitnessHTTPToHTTPS"
    redirect_type        = "Permanent"
    target_listener_name = "FitnessHTTPSListener"
    include_path         = true
    include_query_string = true
  }

  redirect_configuration {
    name                 = "OrganicHTTPToHTTPS"
    redirect_type        = "Permanent"
    target_listener_name = "OrganicHTTPSListener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                       = "FitnessHTTPSRule"
    rule_type                  = "Basic"
    priority                   = 300
    http_listener_name         = "FitnessHTTPSListener"
    backend_address_pool_name  = "FitnessBackendPool"
    backend_http_settings_name = "HTTPBackendSetting"
  }

  request_routing_rule {
    name                       = "OrganicHTTPSRule"
    rule_type                  = "Basic"
    priority                   = 400
    http_listener_name         = "OrganicHTTPSListener"
    backend_address_pool_name  = "OrganicBackendPool"
    backend_http_settings_name = "HTTPBackendSetting"
  }

  request_routing_rule {
    name                        = "FitnessRedirectRule"
    rule_type                   = "Basic"
    priority                    = 500
    http_listener_name          = "FitnessHTTPListener"
    redirect_configuration_name = "FitnessHTTPToHTTPS"
  }

  request_routing_rule {
    name                        = "OrganicRedirectRule"
    rule_type                   = "Basic"
    priority                    = 600
    http_listener_name          = "OrganicHTTPListener"
    redirect_configuration_name = "OrganicHTTPToHTTPS"
  }
}