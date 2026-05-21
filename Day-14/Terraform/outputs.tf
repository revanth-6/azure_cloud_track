output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = module.networking.vnet_name
}

output "fitness_vm_private_ip" {
  description = "Private IP of VM-Fitness (Fitness Tracker)"
  value       = module.virtual_machines.fitness_vm_private_ip
}

output "organic_vm_private_ip" {
  description = "Private IP of VM-Organic (Organic Ghee)"
  value       = module.virtual_machines.organic_vm_private_ip
}

output "appgw_public_ip" {
  description = "Application Gateway Public IP — add to GoDaddy DNS"
  value       = module.application_gateway.appgw_public_ip
}

output "fitness_url" {
  description = "HTTPS URL for Fitness Tracker"
  value       = "https://${var.fitness_hostname}"
}

output "organic_url" {
  description = "HTTPS URL for Organic Ghee"
  value       = "https://${var.organic_hostname}"
}

output "next_steps" {
  description = "What to do after terraform apply completes"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════╗
    ║            TERRAFORM APPLY COMPLETED SUCCESSFULLY            ║
    ╚══════════════════════════════════════════════════════════════╝

    STEP 1 → Go to GoDaddy DNS for medishift.co.in
    STEP 2 → Add/Update A Records:
               fitness  →  ${module.application_gateway.appgw_public_ip}
               organic  →  ${module.application_gateway.appgw_public_ip}
    STEP 3 → Wait 5-10 mins for DNS propagation
    STEP 4 → Wait 10-15 mins for cloud-init to install apps on VMs
             (MongoDB + Node.js + PM2 + Nginx + App clone + npm install)
    STEP 5 → Test in browser:
               https://fitness.medishift.co.in  →  Fitness Tracker
               https://organic.medishift.co.in  →  Organic Ghee

    TROUBLESHOOTING:
    - If 502 Bad Gateway → cloud-init may still be running, wait 5 more mins
    - To check cloud-init status: SSH into VM → cat /var/log/bootstrap.log
    - DNS not resolving: check dnschecker.org
  EOT
}