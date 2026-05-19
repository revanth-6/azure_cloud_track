resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_sku
  instances           = var.instance_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  upgrade_mode = "Automatic"

  custom_data = var.bootstrap_script_base64

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "vmss-ip-config"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.lb_backend_pool_id]
    }
  }

  health_probe_id = var.lb_probe_id

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT30M"
  }

  overprovision = true

  tags = var.tags

  lifecycle {
    ignore_changes = [instances]
  }

  depends_on = [var.lb_rule_id]
}