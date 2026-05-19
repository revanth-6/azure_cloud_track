terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
  }
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

locals {
  bootstrap_script = base64encode(file("${path.module}/bootstrap.sh"))
}

module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.location
  vnet_name            = var.vnet_name
  vnet_address_space   = var.vnet_address_space
  subnet_name          = var.subnet_name
  subnet_address_prefix = var.subnet_address_prefix
  tags                 = var.tags
}

module "nsg" {
  source = "./modules/nsg"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  nsg_name            = var.nsg_name
  subnet_id           = module.networking.subnet_id
  tags                = var.tags
}

module "load_balancer" {
  source = "./modules/load_balancer"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  lb_name             = var.lb_name
  public_ip_name      = var.public_ip_name
  app_port            = var.app_port
  tags                = var.tags
}

module "vmss" {
  source = "./modules/vmss"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.location
  vmss_name                  = var.vmss_name
  vm_sku                     = var.vm_sku
  instance_count             = var.instance_count
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  subnet_id                  = module.networking.subnet_id
  lb_backend_pool_id         = module.load_balancer.backend_pool_id
  lb_probe_id                = module.load_balancer.probe_id
  lb_rule_id                 = module.load_balancer.lb_rule_id
  os_disk_size_gb            = var.os_disk_size_gb
  bootstrap_script_base64    = local.bootstrap_script
  tags                       = var.tags
}

module "autoscaling" {
  source = "./modules/autoscaling"

  resource_group_name     = module.resource_group.resource_group_name
  location                = module.resource_group.location
  autoscale_name          = var.autoscale_name
  vmss_id                 = module.vmss.vmss_id
  min_instances           = var.min_instances
  max_instances           = var.max_instances
  default_instances       = var.default_instances
  scale_out_cpu_threshold = var.scale_out_cpu_threshold
  scale_in_cpu_threshold  = var.scale_in_cpu_threshold
  tags                    = var.tags
}

module "service_bus" {
  source = "./modules/service_bus"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.location
  servicebus_namespace_name  = var.servicebus_namespace_name
  servicebus_topic_name      = var.servicebus_topic_name
  servicebus_subscription_name = var.servicebus_subscription_name
  tags                       = var.tags
}

module "logic_app" {
  source = "./modules/logic_app"

  resource_group_name           = module.resource_group.resource_group_name
  location                      = module.resource_group.location
  logic_app_name                = var.logic_app_name
  servicebus_connection_string  = module.service_bus.primary_connection_string
  servicebus_topic_name         = var.servicebus_topic_name
  servicebus_namespace_endpoint = module.service_bus.namespace_endpoint
  servicebus_sas_token          = "SharedAccessSignature sr=${module.service_bus.namespace_name}.servicebus.windows.net&sig=${module.service_bus.primary_key}&se=9999999999&skn=RootManageSharedAccessKey"
  alert_email                   = var.alert_email
  tags                          = var.tags
}

module "monitor" {
  source = "./modules/monitor"

  resource_group_name     = module.resource_group.resource_group_name
  location                = module.resource_group.location
  resource_group_id       = module.resource_group.resource_group_id
  vmss_id                 = module.vmss.vmss_id
  action_group_name       = var.action_group_name
  alert_rule_name         = var.alert_rule_name
  alert_email             = var.alert_email
  logic_app_webhook_url   = module.logic_app.webhook_url
  cpu_threshold           = var.scale_out_cpu_threshold
  tags                    = var.tags
}