resource "azurerm_public_ip" "nat" {
  name                = "NAT-PublicIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "main" {
  name                    = var.nat_gateway_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "fitness" {
  subnet_id      = var.fitness_subnet_id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "organic" {
  subnet_id      = var.organic_subnet_id
  nat_gateway_id = azurerm_nat_gateway.main.id
}