resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "afd-medishift-${var.environment}"
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor" # Premium required for private link and advanced WAF
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "endpoint-medishift-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  tags                     = var.tags
}

# Edge WAF Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = "wafpolicymedishiftedge${var.environment}"
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.fd.sku_name
  mode                = "Prevention"
  redirect_url        = "https://www.medishift-${var.environment}.com/blocked"

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  tags = var.tags
}

# Security Policy linking WAF to the Endpoint
resource "azurerm_cdn_frontdoor_security_policy" "sec_policy" {
  name                     = "sec-policy-medishift"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Origin Group targeting Application Gateway
resource "azurerm_cdn_frontdoor_origin_group" "appgw_group" {
  name                     = "og-medishift-appgw"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  session_affinity_enabled = false

  health_probe {
    path                = "/" # Probes the root of App Gateway (frontend service)
    protocol            = "Https"
    request_type        = "HEAD"
    interval_in_seconds = 30
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# Origin (Application Gateway Public DNS)
resource "azurerm_cdn_frontdoor_origin" "appgw_origin" {
  name                           = "origin-medishift-appgw"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.appgw_group.id
  enabled                        = true
  certificate_name_check_enabled = false # Disabled for self-signed certificates during bootstrapping

  host_name          = var.appgw_fqdn
  http_port          = 80
  https_port         = 443
  origin_host_header = var.appgw_fqdn
  priority           = 1
  weight             = 1000
}

# Front Door Route (routing all traffic to App Gateway)
resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "route-all-to-appgw"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.appgw_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.appgw_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly" # Forces HTTPS on the backend connection to Application Gateway
  link_to_default_domain = true

  # Caching disabled to prevent caching dynamic APIs (leaves, shifts, auth)
  cache {
    query_string_caching_behavior = "IgnoreQueryString"
  }
}
