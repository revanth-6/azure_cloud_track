terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "dcf95f23-e23c-4b3d-a7ee-cd524c063f88"
}

# Creating resource group
resource "azurerm_resource_group" "demo_rg" {
  name     = "demo-rg"
  location = "Central India"

  tags = {
    environment = "demo"
    project     = "terraform-learning"
  }
}

# Creating vnet
resource "azurerm_virtual_network" "demo_vnet" {
  name                = "demo-vnet"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location = azurerm_resource_group.demo_rg.location
  address_space = ["10.0.0.0/16"]

  tags = {
    environment = "demo"
    project     = "terraform-learning"
  }
}

# Creating subnet
resource "azurerm_subnet" "demo_subnet" {
  name                 = "demo-subnet"
  resource_group_name  = azurerm_resource_group.demo_rg.name
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Creating NSG
resource "azurerm_network_security_group" "demo_nsg" {
  name                = "demo-nsg"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location            = azurerm_resource_group.demo_rg.location

  # Inbound rules
  security_rule {
    name                       = "Allow-SSH-Inbound"
    priority                   = 100
    protocol                   = "Tcp"
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    access                     = "Allow"
  }
  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 110
    protocol                   = "Tcp"
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    access                     = "Allow"
  }
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 120
    protocol                   = "Tcp"
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    access                     = "Allow"
  }
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    protocol                   = "*"
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    access                     = "Deny"
  }

  # Outbound rules
  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 100
    protocol                   = "Tcp"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
    access                     = "Allow"
  }
  security_rule {
    name                       = "Allow-HTTPS-Outbound"
    priority                   = 110
    protocol                   = "Tcp"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "443"
    access                     = "Allow"
  }
  security_rule {
    name                       = "Allow-DNS-Outbound"
    priority                   = 120
    protocol                   = "Udp"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "53"
    access                     = "Allow"
  }
  security_rule {
    name                       = "Deny-All-Outbound"
    priority                   = 4096
    protocol                   = "*"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    access                     = "Deny"
  }

  tags = {
    environment = "demo"
    project     = "terraform-learning"
  }
}

# Associating NSG to subnet
resource "azurerm_subnet_network_security_group_association" "demo_nsg_association" {
  subnet_id                 = azurerm_subnet.demo_subnet.id
  network_security_group_id = azurerm_network_security_group.demo_nsg.id
}

# Public IP
resource "azurerm_public_ip" "demo_public_ip" {
  name                = "demo-public-ip"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    environment = "demo"
    project     = "terraform-learning"
  }
}

# Creating NIC
resource "azurerm_network_interface" "demo_nic" {
  name                = "demo-nic"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name

  ip_configuration {
    name                          = "demo-ip-config"
    subnet_id                     = azurerm_subnet.demo_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_public_ip.id
  }

  tags = {
    environment = "demo"
    project     = "terraform-learning"
  }
}

# Creating VM
resource "azurerm_linux_virtual_machine" "demo_vm" {
  name                            = "demo-vm"
  resource_group_name             = azurerm_resource_group.demo_rg.name
  location                        = azurerm_resource_group.demo_rg.location
  size                            = "Standard_D2s_v5"
  admin_username                  = "azureuser"
  admin_password                  = "Revanth@562004"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.demo_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    environment = "demo"
    project     = "terraform-learning"
  }
}
