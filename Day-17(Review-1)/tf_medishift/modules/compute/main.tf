# Standalone VM for Backend Microservices
resource "azurerm_network_interface" "microservices" {
  name                = "${var.microservices_vm_name}-NIC"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.microservices_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "microservices" {
  name                            = var.microservices_vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.microservices.id
  ]

  os_disk {
    name                 = "${var.microservices_vm_name}-OSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  custom_data = base64encode(
    templatefile("${path.root}/scripts/microservices-bootstrap.sh.tpl", {
      admin_username     = var.admin_username
      identity_client_id = var.identity_client_id
      storage_account    = var.storage_account_name
      storage_container  = var.storage_container_name
      blob_name          = var.blob_name
      db_host            = var.db_host
      db_user            = var.db_user
      db_pass            = var.db_pass
      db_name            = var.db_name
      jwt_secret         = var.jwt_secret
    })
  )
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "microservices" {
  network_interface_id    = azurerm_network_interface.microservices.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = var.appgw_microservices_backend_pool_id
}

# ─────────────────────────────────────────────
# VMSS FOR FRONTEND
# ─────────────────────────────────────────────
resource "azurerm_linux_virtual_machine_scale_set" "frontend" {
  name                            = var.frontend_vmss_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  sku                             = var.vm_size
  instances                       = var.frontend_instances_count
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags

  upgrade_mode = "Manual"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  network_interface {
    name    = "frontend-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.frontend_subnet_id
      application_gateway_backend_address_pool_ids = [var.appgw_frontend_backend_pool_id]
    }
  }

  custom_data = base64encode(
    templatefile("${path.root}/scripts/frontend-bootstrap.sh.tpl", {
      admin_username     = var.admin_username
      identity_client_id = var.identity_client_id
      storage_account    = var.storage_account_name
      storage_container  = var.storage_container_name
      blob_name          = var.blob_name
    })
  )
}
