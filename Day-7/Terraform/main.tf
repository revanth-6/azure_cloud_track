terraform {
    required_providers {
      azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 3.0"
      }
    }
    required_version = ">=1.0"
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.vm1_location

  tags = {
    Project = "FitTrack"
    Environment = "Production"
    CreatedBy = "Terraform"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "VNet-1"
  location            = var.vm1_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet1_address_space]

  tags = {
    name = "VNet-1-CentralIndia"
  }
}
resource "azurerm_subnet" "subnet1" {
  name                = "Subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.subnet1_prefix]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "VNet-2"
  location            = var.vm2_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet2_address_space]

  tags = {
    name = "VNet-2-EastUS"
  }
}
resource "azurerm_subnet" "subnet2" {
  name                = "Subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [var.subnet2_prefix]
}

resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                     = "VNet1-to-VNet2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit = false
  use_remote_gateways = false
}
resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                     = "VNet2-to-VNet1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
}

resource "azurerm_network_security_group" "nsg_vm1" {
  name = "NSG-VM1"
  location = var.vm1_location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name = "Allow-SSH"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name = "Allow-App-Port-5000"
    priority = 110
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "5000"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  tags = {
    name = "NSG-VM1-Frontend"
  }
}
resource "azurerm_network_security_group" "nsg_vm2" {
  name = "NSG-VM2"
  location = var.vm2_location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name = "Allow-SSH"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name = "Allow-MongoDB-From-VM1"
    priority = 110
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "27017"
    source_address_prefix = var.vnet1_address_space
    destination_address_prefix = "*"
  }

  tags = {
    name = "NSG-VM2-Database"
  }
}

resource "azurerm_public_ip" "pip_vm1" {
  name = "PIP-VM1"
  location = var.vm1_location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = "Standard"

  tags = {
    name = "PublicIP-VM1"
  }
}
resource "azurerm_public_ip" "pip_vm2" {
  name = "PIP-VM2"
  location = var.vm2_location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = "Standard"

  tags = {
    name = "PublicIP-VM2"
  }
}

resource "azurerm_network_interface" "nic_vm1" {
  name = "NIC-VM1"
  location = var.vm1_location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig-vm1"
    subnet_id = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip_vm1.id
  }

  tags = {
    name = "NIC-VM1-Frontend"
  }
}
resource "azurerm_network_interface" "nic_vm2" {
  name = "NIC-VM2"
  location = var.vm2_location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig-vm2"
    subnet_id = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip_vm2.id
  }

  tags = {
    name = "NIC-VM2-Database"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm1" {
  network_interface_id = azurerm_network_interface.nic_vm1.id
  network_security_group_id = azurerm_network_security_group.nsg_vm1.id
}
resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm2" {
  network_interface_id = azurerm_network_interface.nic_vm2.id
  network_security_group_id = azurerm_network_security_group.nsg_vm2.id
}
