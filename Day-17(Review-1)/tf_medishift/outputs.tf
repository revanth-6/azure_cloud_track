output "resource_group_name" {
  description = "The deployed resource group name"
  value       = module.resource_group.resource_group_name
}

output "appgw_public_ip" {
  description = "The public IP address of the Application Gateway (map your A records here)"
  value       = module.application_gateway.appgw_public_ip
}

output "application_url" {
  description = "The access URL for the MediShift Application"
  value       = "http://${var.hostname}"
}

output "microservices_private_ip" {
  description = "The private IP address of the backend Microservices VM"
  value       = module.compute.microservices_private_ip
}

output "storage_account_name" {
  description = "The storage account name created for deploying backup assets"
  value       = module.storage.storage_account_name
}

output "postgres_server_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server"
  value       = module.database.postgres_server_fqdn
}

output "next_steps" {
  description = "Instructions for what to do after deployment finishes"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════╗
    ║            MEDISHIFT DEPLOYMENT INITIALIZED                  ║
    ╚══════════════════════════════════════════════════════════════╝

    STEP 1 → Configure your Domain DNS:
             Create or update A records for:
             - Hostname: ${var.hostname}  →  ${module.application_gateway.appgw_public_ip}

    STEP 2 → Wait for DNS propagation (approx. 5-10 minutes)

    STEP 3 → Wait for Cloud-Init / VM bootstrapping to finish (approx. 10-15 minutes).
             The VMs will natively perform:
             - Installing Node.js, Nginx, PM2, and git.
             - Cloning the latest codebase natively from GitHub: https://github.com/MediShift-devops-project/MediShift_v1.git.
             - Resolving database schemas automatically via Sequelize sync on startup.
             - Deploying frontend static files and microservice processes under PM2.

    TROUBLESHOOTING & MONITORING:
    - You can monitor the VM and VMSS instances using Azure Bastion.
    - SSH into the compute instances and check the installation log file:
      tail -f /var/log/bootstrap.log
    - Verify backend status:
      pm2 list
      pm2 logs
    - Check Nginx configurations:
      nginx -t
      systemctl status nginx
  EOT
}
