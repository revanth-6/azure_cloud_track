output "deployment_summary" {
  description = "Complete Deployment Summary"
  value       = <<-EOT

    ============================================
    DEPLOYMENT SUMMARY
    ============================================

    RESOURCE GROUP:
      Name     : ${azurerm_resource_group.rg.name}
      Location : ${azurerm_resource_group.rg.location}

    VIRTUAL NETWORK:
      Name     : ${azurerm_virtual_network.vnet.name}
      Address  : ${join(", ", azurerm_virtual_network.vnet.address_space)}

    SUBNETS:
      Public   : ${azurerm_subnet.public.name} (${join(", ", azurerm_subnet.public.address_prefixes)})
      Private  : ${azurerm_subnet.private.name} (${join(", ", azurerm_subnet.private.address_prefixes)})
      AppGW    : ${azurerm_subnet.appgw.name} (${join(", ", azurerm_subnet.appgw.address_prefixes)})

    NSGs:
      Public   : ${azurerm_network_security_group.public_nsg.name} -> Allow 22, 80, 443
      Private  : ${azurerm_network_security_group.private_nsg.name} -> Allow 5656, 22 (restricted)

    PUBLIC IPs:
      PublicVM     : ${azurerm_public_ip.publicvm_pip.ip_address}
      NAT Gateway  : ${azurerm_public_ip.natgw_pip.ip_address}
      App Gateway  : ${azurerm_public_ip.appgw_pip.ip_address}

    VIRTUAL MACHINES:
      PublicVM:
        - Name       : ${azurerm_linux_virtual_machine.public_vm.name}
        - Public IP   : ${azurerm_public_ip.publicvm_pip.ip_address}
        - Private IP  : ${azurerm_network_interface.public_nic.private_ip_address}
        - App         : Nginx :80

      PrivateVM:
        - Name       : ${azurerm_linux_virtual_machine.private_vm.name}
        - Public IP   : NONE
        - Private IP  : ${azurerm_network_interface.private_nic.private_ip_address}
        - App         : Node.js :${var.node_app_port}
        - Database    : MongoDB :27017

    NAT GATEWAY:
      Name         : ${azurerm_nat_gateway.natgw.name}
      Public IP    : ${azurerm_public_ip.natgw_pip.ip_address}
      Attached To  : ${azurerm_subnet.private.name}
      Purpose      : Outbound internet for PrivateVM

    APPLICATION GATEWAY:
      Name         : ${azurerm_application_gateway.appgw.name}
      Public IP    : ${azurerm_public_ip.appgw_pip.ip_address}
      Backend      : ${azurerm_network_interface.private_nic.private_ip_address}:${var.node_app_port}
      Purpose      : Expose PrivateVM app to internet

    ============================================
    ACCESS URLS
    ============================================
    Nginx (PublicVM)    : http://${azurerm_public_ip.publicvm_pip.ip_address}
    Node.js (PrivateVM) : http://${azurerm_public_ip.appgw_pip.ip_address}

    ============================================
    SSH ACCESS
    ============================================
    Step 1: ssh ${var.admin_username}@${azurerm_public_ip.publicvm_pip.ip_address}
    Step 2: ssh ${var.admin_username}@${azurerm_network_interface.private_nic.private_ip_address}

    ============================================
    TRAFFIC FLOW
    ============================================
    PUBLIC VM INBOUND:
      Internet -> ${azurerm_public_ip.publicvm_pip.ip_address}:80 -> PublicVM (Nginx)

    PRIVATE VM INBOUND:
      Internet -> ${azurerm_public_ip.appgw_pip.ip_address}:80 -> AppGW -> ${azurerm_network_interface.private_nic.private_ip_address}:${var.node_app_port} (Node.js)

    PRIVATE VM OUTBOUND:
      PrivateVM -> NAT Gateway -> ${azurerm_public_ip.natgw_pip.ip_address} -> Internet

    ============================================

  EOT
}
