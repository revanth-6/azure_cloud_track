module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.default_tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name       = module.resource_group.resource_group_name
  location                  = module.resource_group.location
  vnet_name                 = var.vnet_name
  vnet_address_space        = var.vnet_address_space
  appgw_subnet_name         = var.appgw_subnet_name
  appgw_subnet_cidr         = var.appgw_subnet_cidr
  frontend_subnet_name       = var.frontend_subnet_name
  frontend_subnet_cidr       = var.frontend_subnet_cidr
  microservices_subnet_name = var.microservices_subnet_name
  microservices_subnet_cidr = var.microservices_subnet_cidr
  postgres_subnet_name      = var.postgres_subnet_name
  postgres_subnet_cidr      = var.postgres_subnet_cidr
  bastion_subnet_cidr       = var.bastion_subnet_cidr
  nat_gateway_name          = var.nat_gateway_name
  tags                      = local.default_tags
}

module "storage" {
  source = "./modules/storage"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  tags                = local.default_tags
}

module "security" {
  source = "./modules/security"

  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.location
  identity_name        = var.identity_name
  storage_container_id = module.storage.storage_container_id
  tags                 = local.default_tags
}

module "database" {
  source = "./modules/database"

  resource_group_name     = module.resource_group.resource_group_name
  location                = module.resource_group.location
  postgres_server_name    = var.postgres_server_name
  postgres_subnet_id      = module.networking.postgres_subnet_id
  private_dns_zone_id      = module.networking.private_dns_zone_id
  postgres_admin_username = var.postgres_admin_username
  postgres_admin_password = var.postgres_admin_password
  postgres_sku_name       = var.postgres_sku_name
  tags                    = local.default_tags
}

module "application_gateway" {
  source = "./modules/application_gateway"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  appgw_name          = var.appgw_name
  appgw_subnet_id     = module.networking.appgw_subnet_id
  tags                = local.default_tags
}

module "compute" {
  source = "./modules/compute"

  resource_group_name                  = module.resource_group.resource_group_name
  location                             = module.resource_group.location
  microservices_vm_name                = var.microservices_vm_name
  frontend_vmss_name                   = var.frontend_vmss_name
  vm_size                              = var.vm_size
  admin_username                       = var.admin_username
  admin_password                       = var.admin_password
  frontend_subnet_id                   = module.networking.frontend_subnet_id
  microservices_subnet_id               = module.networking.microservices_subnet_id
  identity_id                          = module.security.identity_id
  identity_client_id                   = module.security.identity_client_id
  storage_account_name                 = module.storage.storage_account_name
  storage_container_name               = module.storage.storage_container_name
  blob_name                            = module.storage.blob_name
  db_host                              = module.database.postgres_server_fqdn
  db_user                              = var.postgres_admin_username
  db_pass                              = var.postgres_admin_password
  db_name                              = module.database.postgres_database_name
  jwt_secret                           = local.jwt_secret
  frontend_instances_count             = var.frontend_instances_count
  appgw_frontend_backend_pool_id       = module.application_gateway.frontend_backend_pool_id
  appgw_microservices_backend_pool_id  = module.application_gateway.microservices_backend_pool_id
  tags                                 = local.default_tags

  # Ensure resources are created after the database is ready
  depends_on = [module.database]
}
