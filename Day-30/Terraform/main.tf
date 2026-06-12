data "azurerm_client_config" "current" {}

locals {
  environment = terraform.workspace == "default" ? var.environment : terraform.workspace
  node_env    = local.environment == "prod" ? "production" : "development"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name == "rg-medishift-prod" && local.environment != "prod" ? "rg-medishift-${local.environment}" : var.resource_group_name
  location = var.primary_location
  tags     = var.tags
}

# 1. Networking Module
module "networking" {
  source                        = "./modules/networking"
  location                      = var.primary_location
  resource_group_name           = azurerm_resource_group.rg.name
  vnet_cidr                     = var.vnet_cidr
  subnet_appgw_cidr             = var.subnet_appgw_cidr
  subnet_aks_cidr               = var.subnet_aks_cidr
  subnet_postgres_cidr          = var.subnet_postgres_cidr
  subnet_private_endpoints_cidr = var.subnet_private_endpoints_cidr
  tags                          = var.tags
  environment                   = local.environment
}

# 2. Identity Module (requires AKS OIDC URL, handled via dependency below)
module "identity" {
  source              = "./modules/identity"
  location            = var.primary_location
  resource_group_name = azurerm_resource_group.rg.name
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  tags                = var.tags
  environment         = local.environment
}

# 3. Storage Module
module "storage" {
  source                      = "./modules/storage"
  location                    = var.primary_location
  resource_group_name         = azurerm_resource_group.rg.name
  vnet_id                     = module.networking.vnet_id
  subnet_private_endpoints_id = module.networking.subnet_private_endpoints_id
  tags                        = var.tags
  environment                 = local.environment
  storage_replication_type    = var.storage_replication_type
}

# 4. Security Module (Creates Key Vault and ACR Premium)
module "security" {
  source                             = "./modules/security"
  location                           = var.primary_location
  dr_location                        = var.dr_location
  resource_group_name                = azurerm_resource_group.rg.name
  vnet_id                            = module.networking.vnet_id
  subnet_private_endpoints_id        = module.networking.subnet_private_endpoints_id
  aks_workload_identity_principal_id = module.identity.aks_workload_identity_principal_id
  postgres_admin_user                = var.postgres_admin_user
  postgres_host                      = module.database.postgres_fqdn
  tags                               = var.tags
  environment                        = local.environment
  georeplication_enabled             = var.georeplication_enabled
  postgres_sku_name                  = var.postgres_sku_name
}

# 5. Database Module (PostgreSQL with native PgBouncer)
module "database" {
  source                     = "./modules/database"
  location                   = var.primary_location
  resource_group_name        = azurerm_resource_group.rg.name
  vnet_id                    = module.networking.vnet_id
  subnet_postgres_id         = module.networking.subnet_postgres_id
  postgres_version           = var.postgres_version
  postgres_sku_name          = var.postgres_sku_name
  postgres_admin_user        = var.postgres_admin_user
  postgres_admin_password    = module.security.postgres_password
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = var.tags
  environment                = local.environment
}

# 6. AKS Module (Private Cluster with CSI and OIDC)
module "aks" {
  source                     = "./modules/aks"
  location                   = var.primary_location
  resource_group_name        = azurerm_resource_group.rg.name
  subnet_aks_id              = module.networking.subnet_aks_id
  aks_vm_size                = var.aks_vm_size
  aks_system_node_count      = var.aks_system_node_count
  aks_user_min_nodes         = var.aks_user_min_nodes
  aks_user_max_nodes         = var.aks_user_max_nodes
  acr_id                     = module.security.acr_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = var.tags
  environment                = local.environment
}

# Dynamic Provider Configuration for Kubernetes and Helm
provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

# 7. Ingress Module (Deploys NGINX Ingress on static IP via Helm)
module "ingress" {
  source                      = "./modules/ingress"
  controller_load_balancer_ip = "10.0.2.254"
  depends_on                  = [module.aks]
}

# 8. App Gateway Module
module "appgateway" {
  source                     = "./modules/appgateway"
  location                   = var.primary_location
  resource_group_name        = azurerm_resource_group.rg.name
  subnet_appgw_id            = module.networking.subnet_appgw_id
  subnet_aks_cidr            = module.networking.subnet_aks_cidr
  appgw_identity_id          = module.identity.appgw_identity_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  ssl_cert_data              = filebase64("${path.module}/dummy-cert.pfx")
  ssl_cert_password          = "medishift123"
  tags                       = var.tags
  environment                = local.environment
  appgw_min_capacity         = var.appgw_min_capacity
  appgw_max_capacity         = var.appgw_max_capacity
  depends_on                 = [module.ingress]
}

# 9. Front Door Module (Commented out due to Free Trial subscription constraints)
# module "frontdoor" {
#   source              = "./modules/frontdoor"
#   resource_group_name = azurerm_resource_group.rg.name
#   appgw_fqdn          = module.appgateway.public_ip_fqdn
#   tags                = var.tags
#   environment         = local.environment
# }

# 10. Monitoring Module (Managed Prometheus & Grafana, Alerting)
module "monitoring" {
  source              = "./modules/monitoring"
  location            = var.primary_location
  resource_group_name = azurerm_resource_group.rg.name
  subscription_id     = var.subscription_id
  aks_cluster_id      = module.aks.cluster_id
  appgw_id            = module.appgateway.appgw_id
  postgres_id         = module.database.postgres_id
  tags                = var.tags
  environment         = local.environment
}

# 11. Render Kubernetes manifests dynamically
resource "local_file" "rendered_namespace" {
  content  = templatefile("${path.module}/k8s_templates/namespace.yaml", { environment = local.environment })
  filename = "${path.module}/k8s_rendered/namespace.yaml"
}

resource "local_file" "rendered_configmap" {
  content  = templatefile("${path.module}/k8s_templates/configmap.yaml", { environment = local.environment, node_env = local.node_env })
  filename = "${path.module}/k8s_rendered/configmap.yaml"
}

resource "local_file" "rendered_secrets_store" {
  content = templatefile("${path.module}/k8s_templates/secrets-store-inline.yaml", {
    environment        = local.environment
    keyvault_name      = module.security.key_vault_name
    tenant_id          = data.azurerm_client_config.current.tenant_id
    workload_client_id = module.identity.aks_workload_identity_client_id
  })
  filename = "${path.module}/k8s_rendered/secrets-store-inline.yaml"
}

resource "local_file" "rendered_deployments" {
  content = templatefile("${path.module}/k8s_templates/deployments.yaml", {
    environment        = local.environment
    workload_client_id = module.identity.aks_workload_identity_client_id
    postgres_fqdn      = module.database.postgres_fqdn
    postgres_port      = startswith(var.postgres_sku_name, "B_") ? "5432" : "6432"
  })
  filename = "${path.module}/k8s_rendered/deployments.yaml"
}

resource "local_file" "rendered_hpa" {
  content  = templatefile("${path.module}/k8s_templates/hpa.yaml", { environment = local.environment })
  filename = "${path.module}/k8s_rendered/hpa.yaml"
}

resource "local_file" "rendered_ingress" {
  content  = templatefile("${path.module}/k8s_templates/ingress.yaml", { environment = local.environment })
  filename = "${path.module}/k8s_rendered/ingress.yaml"
}

resource "local_file" "rendered_network_policies" {
  content = templatefile("${path.module}/k8s_templates/network-policies.yaml", {
    environment   = local.environment
    postgres_port = startswith(var.postgres_sku_name, "B_") ? "5432" : "6432"
  })
  filename = "${path.module}/k8s_rendered/network-policies.yaml"
}

resource "local_file" "rendered_pdb" {
  content  = templatefile("${path.module}/k8s_templates/pdb.yaml", { environment = local.environment })
  filename = "${path.module}/k8s_rendered/pdb.yaml"
}

resource "local_file" "rendered_services" {
  content  = templatefile("${path.module}/k8s_templates/services.yaml", { environment = local.environment })
  filename = "${path.module}/k8s_rendered/services.yaml"
}
