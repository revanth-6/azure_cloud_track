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
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "public" {
  name                 = var.public_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.public_subnet_prefix
}

resource "azurerm_subnet" "private" {
  name                 = var.private_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_subnet_prefix
}

resource "azurerm_subnet" "appgw" {
  name                 = var.appgw_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.appgw_subnet_prefix
}

resource "azurerm_network_security_group" "public_nsg" {
  name                = "PublicNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "private_nsg" {
  name                = "PrivateNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowAppGWHealthProbe"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowNodeAppFromAppGW"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.node_app_port)
    source_address_prefix      = var.appgw_subnet_prefix[0]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTPFromAppGW"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.appgw_subnet_prefix[0]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTPFromPublicSubnet"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.public_subnet_prefix[0]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowSSHFromPublicSubnet"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.public_subnet_prefix[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_public_ip" "publicvm_pip" {
  name                = "PublicVM-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "natgw_pip" {
  name                = "NATGW-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "AppGW-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "public_nic" {
  name                = "PublicVM-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "PublicVM-ipconfig"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicvm_pip.id
  }

  tags = var.tags
}

resource "azurerm_network_interface" "private_nic" {
  name                = "PrivateVM-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "PrivateVM-ipconfig"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "public_vm" {
  name                = var.public_vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  tags = var.tags

  network_interface_ids = [
    azurerm_network_interface.public_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "PublicVM-osdisk"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "<h1> PublicVM - Nginx is running </h1>" | sudo tee /var/www/html/index.html
  EOF
  )
}

resource "azurerm_linux_virtual_machine" "private_vm" {
  name                = var.private_vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  tags = var.tags

  network_interface_ids = [
    azurerm_network_interface.private_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "PrivateVM-osdisk"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update -y

    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nginx nodejs

    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt update -y
    sudo apt install -y mongodb-org
    sudo systemctl start mongod
    sudo systemctl enable mongod

    sudo apt install -y git
    cd /home/${var.admin_username}
    git clone https://github.com/Msocial123/organic-ghee.git
    cd organic-ghee

    npm install

    sudo npm install -g nodemon
    sudo npm install -g pm2
    pm2 start src/app.js --name "organic-ghee"
    pm2 save
    pm2 startup systemd -u ${var.admin_username} --hp /home/${var.admin_username}  
  EOF
  )

  depends_on = [
    azurerm_subnet_network_security_group_association.private_nsg_assoc
  ]
}

resource "azurerm_nat_gateway" "natgw" {
  name                = var.nat_gateway_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
  idle_timeout_in_minutes = var.nat_idle_timeout
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id = azurerm_nat_gateway.natgw.id
  public_ip_address_id   = azurerm_public_ip.natgw_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "private_subnet_natgw_assoc" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.app_gateway_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  sku {
    name     = var.app_gateway_sku_size
    tier     = var.app_gateway_sku_tier
    capacity = var.app_gateway_capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ipconfig"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "appgw-frontendPort"
    port = var.nginx_port
  }

  backend_address_pool {
    name         = "PrivateVM-BackendPool"
    ip_addresses = [azurerm_network_interface.private_nic.private_ip_address]
  }

  backend_http_settings {
    name                  = "HTTP-Settings"
    cookie_based_affinity = "Disabled"
    port                  = var.node_app_port
    protocol              = "Http"
    request_timeout       = 20
    probe_name            = "health-Probe"
  }

  probe {
    name                = "health-Probe"
    protocol            = "Http"
    host                = azurerm_network_interface.private_nic.private_ip_address
    path                = "/"
    port                = var.node_app_port
    interval            = 30
    timeout             = 20
    unhealthy_threshold = 3
  }

  http_listener {
    name = "HTTP-Listener"
    frontend_ip_configuration_name = "appgw-frontend-ipconfig"
    frontend_port_name             = "appgw-frontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name      = "RoutingRule"
    priority  = 100
    rule_type = "Basic"
    http_listener_name         = "HTTP-Listener"
    backend_address_pool_name  = "PrivateVM-BackendPool"
    backend_http_settings_name = "HTTP-Settings"
  }

  depends_on = [
    azurerm_linux_virtual_machine.private_vm,
    azurerm_subnet_network_security_group_association.private_nsg_assoc
  ]
}