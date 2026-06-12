resource "random_string" "appgw_dns_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-medishift-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "medishift-appgw-${random_string.appgw_dns_suffix.result}"
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "waf-policy-medishift"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

locals {
  backend_address_pool_name      = "medishift-nginx-pool"
  frontend_port_http_name        = "http-port"
  frontend_port_https_name       = "https-port"
  frontend_ip_configuration_name = "appgw-frontend-ip"
  http_setting_name              = "medishift-backend-settings"
  listener_http_name             = "medishift-http-listener"
  listener_https_name            = "medishift-https-listener"
  routing_rule_http_name         = "rule-http-redirect"
  routing_rule_https_name        = "rule-https-nginx"
  redirect_configuration_name    = "redirect-http-to-https"
  ssl_certificate_name           = "medishift-ssl-cert"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "agw-medishift-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf.id

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  autoscale_configuration {
    min_capacity = var.appgw_min_capacity
    max_capacity = var.appgw_max_capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_appgw_id
  }

  frontend_port {
    name = local.frontend_port_http_name
    port = 80
  }

  frontend_port {
    name = local.frontend_port_https_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = ["10.0.2.254"] # Points to the static private IP of the internal NGINX Ingress load balancer
  }

  # Backend settings to forward traffic to NGINX Ingress on HTTP Port 80
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "nginx-ingress-probe"
  }

  # Health probe targeting the NGINX Ingress health endpoint
  probe {
    name                = "nginx-ingress-probe"
    protocol            = "Http"
    path                = "/healthz"
    host                = "127.0.0.1" # Standard Ingress healthcheck host
    interval            = 15
    timeout             = 10
    unhealthy_threshold = 3
  }

  # HTTP Listener (Public Entry)
  http_listener {
    name                           = local.listener_http_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_http_name
    protocol                       = "Http"
  }

  # HTTPS Listener with Bootstrapped Self-Signed Certificate
  http_listener {
    name                           = local.listener_https_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_https_name
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_certificate_name
  }

  # Bootstrapping a self-signed certificate for TLS termination 
  # (Can be updated to pull from Key Vault using Managed Identity)
  ssl_certificate {
    name     = local.ssl_certificate_name
    data     = var.ssl_cert_data
    password = var.ssl_cert_password
  }

  # Redirect Configuration (HTTP to HTTPS)
  redirect_configuration {
    name                 = local.redirect_configuration_name
    redirect_type        = "Permanent"
    target_listener_name = local.listener_https_name
    include_path         = true
    include_query_string = true
  }

  # Routing Rule 1: HTTP -> HTTPS redirect
  request_routing_rule {
    name                        = local.routing_rule_http_name
    rule_type                   = "Basic"
    http_listener_name          = local.listener_http_name
    redirect_configuration_name = local.redirect_configuration_name
    priority                    = 100
  }

  # Routing Rule 2: HTTPS -> NGINX Ingress
  request_routing_rule {
    name                       = local.routing_rule_https_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_https_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 110
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.appgw_identity_id]
  }

  tags = var.tags
}

# Diagnostic Settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "ds-appgw"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
