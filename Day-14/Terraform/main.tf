terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  fitness_subnet_name = var.fitness_subnet_name
  fitness_subnet_cidr = var.fitness_subnet_cidr
  organic_subnet_name = var.organic_subnet_name
  organic_subnet_cidr = var.organic_subnet_cidr
  appgw_subnet_name   = var.appgw_subnet_name
  appgw_subnet_cidr   = var.appgw_subnet_cidr
  tags                = var.tags
}

module "nsg" {
  source = "./modules/nsg"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  fitness_subnet_id   = module.networking.fitness_subnet_id
  organic_subnet_id   = module.networking.organic_subnet_id
  appgw_subnet_id     = module.networking.appgw_subnet_id
  tags                = var.tags
}

module "nat_gateway" {
  source = "./modules/nat_gateway"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  nat_gateway_name    = var.nat_gateway_name
  fitness_subnet_id   = module.networking.fitness_subnet_id
  organic_subnet_id   = module.networking.organic_subnet_id
  tags                = var.tags
}

module "virtual_machines" {
  source = "./modules/virtual_machine"

  resource_group_name    = module.resource_group.resource_group_name
  location               = module.resource_group.location
  fitness_vm_name        = var.fitness_vm_name
  organic_vm_name        = var.organic_vm_name
  vm_size                = var.vm_size
  admin_username         = var.admin_username
  admin_password         = var.admin_password
  fitness_subnet_id      = module.networking.fitness_subnet_id
  organic_subnet_id      = module.networking.organic_subnet_id
  fitness_script_path    = var.fitness_script_path
  organic_script_path    = var.organic_script_path
  tags                   = var.tags

  depends_on = [module.nat_gateway]
}

module "application_gateway" {
  source = "./modules/application_gateway"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  appgw_name          = var.appgw_name
  appgw_subnet_id     = module.networking.appgw_subnet_id
  fitness_backend_ip  = module.virtual_machines.fitness_vm_private_ip
  organic_backend_ip  = module.virtual_machines.organic_vm_private_ip
  fitness_hostname    = var.fitness_hostname
  organic_hostname    = var.organic_hostname
  fitness_pfx_path    = var.fitness_pfx_path
  organic_pfx_path    = var.organic_pfx_path
  pfx_password        = var.pfx_password
  tags                = var.tags
}