resource_group_name = "HostRouting-RG"
location            = "Central India"

tags = {
  Project     = "HostBasedRouting"
  Environment = "Production"
  Owner       = "Revanth"
  CreatedBy   = "Terraform"
}

vnet_name          = "HostRouting-VNet"
vnet_address_space = "10.0.0.0/16"

fitness_subnet_name = "Fitness-Subnet"
fitness_subnet_cidr = "10.0.1.0/24"

organic_subnet_name = "Organic-Subnet"
organic_subnet_cidr = "10.0.2.0/24"

appgw_subnet_name = "AppGateway-Subnet"
appgw_subnet_cidr = "10.0.3.0/24"

nat_gateway_name = "HostRouting-NAT"

fitness_vm_name = "VM-Fitness"
organic_vm_name = "VM-Organic"
vm_size         = "Standard_B2ats_v2"
admin_username  = "azureuser"
admin_password  = "Revanth@562004"

fitness_script_path = "scripts/fitness-tracker.sh"
organic_script_path = "scripts/organic-ghee.sh"

appgw_name       = "HostRouting-AppGW"
fitness_hostname = "fitness.medishift.co.in"
organic_hostname = "organic.medishift.co.in"

fitness_pfx_path = "./fitness.pfx"
organic_pfx_path = "./organic.pfx"
pfx_password     = "Password123"