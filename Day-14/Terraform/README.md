# Day-14: Azure Host-Based Routing with Application Gateway WAF v2

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture Diagram](#architecture-diagram)
- [Traffic Flow](#traffic-flow)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Applications Deployed](#applications-deployed)
- [Infrastructure Components](#infrastructure-components)
- [Module Details](#module-details)
- [Script Files](#script-files)
- [How to Deploy](#how-to-deploy)
- [SSL Certificates Setup](#ssl-certificates-setup)
- [DNS Configuration](#dns-configuration)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## Project Overview

This Terraform project deploys a **complete host-based routing infrastructure** on Microsoft Azure.

Two different web applications are hosted on separate Virtual Machines. A single **Application Gateway WAF v2** sits in front of both VMs and routes traffic based on the **hostname** in the HTTP request.

| Hostname | Routes To | Application |
|----------|-----------|-------------|
| `fitness.medishift.co.in` | VM-Fitness | Fitness Tracker App |
| `organic.medishift.co.in` | VM-Organic | Organic Ghee Store |

### Key Features
- ✅ Host-based routing using Azure Application Gateway WAF v2
- ✅ Automatic HTTP → HTTPS redirect (301 Permanent)
- ✅ SSL/TLS termination at Application Gateway level
- ✅ WAF Protection (OWASP 3.2 ruleset in Prevention mode)
- ✅ VMs have NO public IP (private only - secure)
- ✅ NAT Gateway for outbound internet access from VMs
- ✅ Fully automated VM bootstrap via cloud-init scripts
- ✅ MongoDB 7.0 + Node.js 20 + PM2 + Nginx on each VM
- ✅ Modern TLS policy (TLS 1.2+ only)
- ✅ Complete Terraform modular structure

---

## Architecture Diagram

```
                          INTERNET
                             │
                             ▼
                    ┌─────────────────┐
                    │   GoDaddy DNS   │
                    │                 │
                    │ fitness.* ──┐   │
                    │ organic.* ──┤   │
                    └────────────┼───┘
                                 │
                                 ▼
                    ┌─────────────────────┐
                    │   Application       │
                    │   Gateway WAF v2    │
                    │                     │
                    │  Public IP (Static) │
                    │                     │
                    │  WAF: OWASP 3.2     │
                    │  TLS: 1.2+          │
                    │                     │
                    │  Port 80  → 301     │
                    │  Redirect to HTTPS  │
                    │                     │
                    │  Port 443           │
                    │  Host-Based Routing │
                    └──────────┬──────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
              ▼                                 ▼
   fitness.medishift.co.in          organic.medishift.co.in
              │                                 │
              ▼                                 ▼
   ┌─────────────────────┐         ┌─────────────────────┐
   │     VM-Fitness      │         │     VM-Organic       │
   │   (No Public IP)    │         │   (No Public IP)     │
   │                     │         │                      │
   │  Fitness-Subnet     │         │  Organic-Subnet      │
   │  10.0.1.0/24        │         │  10.0.2.0/24         │
   │                     │         │                      │
   │  Nginx :80          │         │  Nginx :80           │
   │    ↓ proxy          │         │    ↓ proxy           │
   │  Node.js :5000      │         │  Node.js :5656       │
   │    ↓                │         │    ↓                 │
   │  MongoDB :27017     │         │  MongoDB :27017      │
   └─────────────────────┘         └──────────────────────┘
              │                                 │
              └────────────────┬────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    NAT Gateway      │
                    │                     │
                    │  Outbound internet  │
                    │  for both VMs       │
                    │  (apt-get, git,     │
                    │   npm installs)     │
                    └─────────────────────┘


VNet: HostRouting-VNet (10.0.0.0/16)
├── Fitness-Subnet     (10.0.1.0/24) → VM-Fitness + Fitness-NSG + NAT
├── Organic-Subnet     (10.0.2.0/24) → VM-Organic + Organic-NSG + NAT
└── AppGateway-Subnet  (10.0.3.0/24) → Application Gateway + AppGW-NSG
```

---

## Traffic Flow

### HTTPS Request Flow
```
User types: https://fitness.medishift.co.in
        │
        ▼
GoDaddy DNS resolves fitness.medishift.co.in → AppGW Public IP
        │
        ▼
Application Gateway receives request on Port 443
        │
        ▼
FitnessHTTPSListener matches hostname: fitness.medishift.co.in
        │
        ▼
SSL certificate (fitness.pfx) terminates TLS
        │
        ▼
FitnessHTTPSRule → forwards to FitnessBackendPool
        │
        ▼
FitnessBackendPool → VM-Fitness Private IP on Port 80
        │
        ▼
Nginx on VM-Fitness receives request on Port 80
        │
        ▼
Nginx proxies to Node.js on Port 5000
        │
        ▼
Fitness Tracker App responds
        │
        ▼
Response travels back to user browser
```

### HTTP → HTTPS Redirect Flow
```
User types: http://fitness.medishift.co.in
        │
        ▼
Application Gateway receives on Port 80
        │
        ▼
FitnessHTTPListener matches hostname
        │
        ▼
FitnessRedirectRule → 301 Permanent Redirect
        │
        ▼
Browser automatically requests https://fitness.medishift.co.in
        │
        ▼
Follows HTTPS flow above ↑
```

---

## Project Structure

```
Day-14/Terraform/
│
├── main.tf                         # Root - calls all 6 modules
├── variables.tf                    # All variable declarations
├── terraform.tfvars                # Actual values (passwords, names)
├── outputs.tf                      # Printed after terraform apply
├── .gitignore                      # Excludes sensitive files
│
├── scripts/
│   ├── fitness-tracker.sh          # Bootstrap script for VM-Fitness
│   └── organic-ghee.sh             # Bootstrap script for VM-Organic
│
└── modules/
    ├── resource_group/
    │   ├── main.tf                 # Creates HostRouting-RG
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── networking/
    │   ├── main.tf                 # VNet + 3 Subnets
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── nsg/
    │   ├── main.tf                 # 3 NSGs + subnet associations
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── nat_gateway/
    │   ├── main.tf                 # NAT Gateway + public IP + associations
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── virtual_machine/
    │   ├── main.tf                 # 2 Linux VMs + NICs + cloud-init
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── application_gateway/
        ├── main.tf                 # AppGW WAF v2 + WAF Policy + routing
        ├── variables.tf
        └── outputs.tf
```

---

## Prerequisites

### Tools Required
```bash
# 1. Terraform (version 1.3.0 or higher)
terraform -version

# 2. Azure CLI
az -version

# 3. Git
git -version

# 4. OpenSSL (for generating SSL certificates)
openssl version
```

### Install Terraform (Windows)
```bash
# Download from: https://developer.hashicorp.com/terraform/downloads
# OR use chocolatey:
choco install terraform
```

### Install Azure CLI (Windows)
```bash
# Download from: https://aka.ms/installazurecliwindows
# OR use winget:
winget install Microsoft.AzureCLI
```

### Azure Login
```bash
# Login to Azure
az login

# Verify correct subscription
az account show

# If multiple subscriptions - set the right one
az account set --subscription "Your-Subscription-Name"
```

---

## Applications Deployed

### Application 1: Fitness Tracker
| Property | Value |
|----------|-------|
| VM Name | VM-Fitness |
| GitHub Repo | https://github.com/Suryaa11/Fitness_Tracker |
| App Port | 5000 (Node.js) |
| Nginx Port | 80 |
| Database | MongoDB 7.0 (fitness-tracker DB) |
| URL | https://fitness.medishift.co.in |

**What bootstrap script does:**
```
1.  System update (apt-get upgrade)
2.  Install: curl, wget, git, nginx, build-essential
3.  Install MongoDB 7.0 (from official MongoDB repo)
4.  Configure MongoDB (bindIp: 127.0.0.1, port: 27017)
5.  Install Node.js 20.x (from NodeSource)
6.  Install PM2 globally (process manager)
7.  Clone Fitness_Tracker from GitHub
8.  Install npm dependencies (root + server/)
9.  Patch nodemon → node in package.json
10. Create .env file (PORT, MONGODB_URI, JWT_SECRET)
11. Detect entry point (server/app.js or app.js)
12. Start app with PM2
13. Configure Nginx reverse proxy (port 80 → 5000)
14. Health check (curl localhost:5000)
```

### Application 2: Organic Ghee Store
| Property | Value |
|----------|-------|
| VM Name | VM-Organic |
| GitHub Repo | https://github.com/Msocial123/organic-ghee |
| App Port | 5656 (Node.js) |
| Nginx Port | 80 |
| Database | MongoDB 7.0 (restorent DB) |
| URL | https://organic.medishift.co.in |

**What bootstrap script does:**
```
1.  System update (apt-get upgrade)
2.  Install: curl, wget, git, nginx, build-essential
3.  Install MongoDB 7.0 (from official MongoDB repo)
4.  Configure MongoDB (bindIp: 127.0.0.1, port: 27017)
5.  Install Node.js 20.x (from NodeSource)
6.  Install PM2 globally
7.  Clone organic-ghee from GitHub
8.  Install npm dependencies
9.  Patch nodemon → node in package.json
10. Create .env file (PORT, MONGODB_URI)
11. Start app with PM2 (entry: src/app.js)
12. Configure Nginx reverse proxy (port 80 → 5656)
13. Health check (curl localhost:5656)
```

---

## Infrastructure Components

### Resource Group
| Property | Value |
|----------|-------|
| Name | HostRouting-RG |
| Region | Central India |

### Virtual Network
| Property | Value |
|----------|-------|
| Name | HostRouting-VNet |
| Address Space | 10.0.0.0/16 |

### Subnets
| Subnet | CIDR | Used For |
|--------|------|----------|
| Fitness-Subnet | 10.0.1.0/24 | VM-Fitness |
| Organic-Subnet | 10.0.2.0/24 | VM-Organic |
| AppGateway-Subnet | 10.0.3.0/24 | Application Gateway (dedicated) |

### Network Security Groups
| NSG | Inbound Rules |
|-----|--------------|
| Fitness-NSG | HTTP (80), SSH (22) |
| Organic-NSG | HTTP (80), SSH (22) |
| AppGW-NSG | HTTP (80), HTTPS (443), GatewayManager (65200-65535) |

> ⚠️ GatewayManager rule (65200-65535) is **mandatory** for Application Gateway to provision successfully.

### NAT Gateway
| Property | Value |
|----------|-------|
| Name | HostRouting-NAT |
| SKU | Standard |
| Idle Timeout | 4 minutes |
| Associated Subnets | Fitness-Subnet, Organic-Subnet |
| Purpose | Outbound internet for VMs (apt-get, git clone, npm install) |

### Virtual Machines
| Property | VM-Fitness | VM-Organic |
|----------|------------|------------|
| Size | Standard_B2s | Standard_B2s |
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| CPU | 2 vCPU | 2 vCPU |
| RAM | 4 GB | 4 GB |
| Disk | 30 GB Standard_LRS | 30 GB Standard_LRS |
| Public IP | None | None |
| Bootstrap | fitness-tracker.sh | organic-ghee.sh |

> 💡 Standard_B2s is required. Standard_B1s (1GB RAM) will crash due to MongoDB + Node.js memory usage.

### Application Gateway
| Property | Value |
|----------|-------|
| Name | HostRouting-AppGW |
| SKU | WAF_v2 |
| Tier | WAF_v2 |
| Autoscale Min | 0 instances |
| Autoscale Max | 2 instances |
| WAF Mode | Prevention |
| WAF Ruleset | OWASP 3.2 |
| TLS Policy | AppGwSslPolicy20220101 (TLS 1.2+) |
| Frontend IP | Static Public IP |

---

## Module Details

### Module 1: resource_group
```hcl
# Creates the resource group that contains all resources
module "resource_group" {
  source              = "./modules/resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
```

### Module 2: networking
```hcl
# Creates VNet and 3 subnets
module "networking" {
  source              = "./modules/networking"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  ...
}
```

### Module 3: nsg
```hcl
# Creates 3 NSGs and associates with subnets
module "nsg" {
  source              = "./modules/nsg"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  fitness_subnet_id   = module.networking.fitness_subnet_id
  organic_subnet_id   = module.networking.organic_subnet_id
  appgw_subnet_id     = module.networking.appgw_subnet_id
  tags                = var.tags
}
```

### Module 4: nat_gateway
```hcl
# Creates NAT Gateway for VM outbound internet
module "nat_gateway" {
  source              = "./modules/nat_gateway"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  nat_gateway_name    = var.nat_gateway_name
  fitness_subnet_id   = module.networking.fitness_subnet_id
  organic_subnet_id   = module.networking.organic_subnet_id
  tags                = var.tags
}
```

### Module 5: virtual_machines
```hcl
# Creates 2 VMs with cloud-init bootstrap scripts
module "virtual_machines" {
  source              = "./modules/virtual_machine"
  fitness_script_path = var.fitness_script_path   # scripts/fitness-tracker.sh
  organic_script_path = var.organic_script_path   # scripts/organic-ghee.sh
  depends_on          = [module.nat_gateway]       # NAT must exist before VMs boot
  ...
}
```

### Module 6: application_gateway
```hcl
# Creates WAF v2 AppGW with host-based routing
module "application_gateway" {
  source             = "./modules/application_gateway"
  fitness_backend_ip = module.virtual_machines.fitness_vm_private_ip
  organic_backend_ip = module.virtual_machines.organic_vm_private_ip
  fitness_hostname   = var.fitness_hostname
  organic_hostname   = var.organic_hostname
  ...
}
```

---

## Script Files

### How Bootstrap Scripts Work

```
terraform apply
      │
      ▼
Terraform reads scripts/fitness-tracker.sh
      │   file("scripts/fitness-tracker.sh")
      ▼
Converts to base64
      │   base64encode(file("scripts/fitness-tracker.sh"))
      ▼
Passes as custom_data to Azure VM
      │
      ▼
VM boots for first time
      │
      ▼
Azure cloud-init decodes base64
      │
      ▼
Runs script as root (like sudo bash fitness-tracker.sh)
      │
      ▼
MongoDB + Node.js + PM2 + Nginx installed automatically
      │
      ▼
App cloned from GitHub and started
      │
      ▼
Nginx configured to proxy port 80 → Node.js port
      │
      ▼
App is ready to receive traffic from Application Gateway
```

### scripts/fitness-tracker.sh
```
Installs  : MongoDB 7.0, Node.js 20.x, PM2, Nginx
Clones    : github.com/Suryaa11/Fitness_Tracker
App Port  : 5000
Nginx Port: 80
DB Name   : fitness-tracker
Log File  : /var/log/bootstrap.log
PM2 Log   : /home/azureuser/fittrack-pro-pm2.log
```

### scripts/organic-ghee.sh
```
Installs  : MongoDB 7.0, Node.js 20.x, PM2, Nginx
Clones    : github.com/Msocial123/organic-ghee
App Port  : 5656
Nginx Port: 80
DB Name   : restorent
Log File  : /var/log/bootstrap.log
PM2 Log   : /home/azureuser/organic-ghee-pm2.log
Entry     : src/app.js
```

---

## How to Deploy

### Step 1: Clone this repository
```bash
git clone https://github.com/revanth-6/azure_cloud_track.git
cd azure_cloud_track/Day-14/Terraform
```

### Step 2: Generate SSL Certificates
```bash
# Option A: Self-signed (for testing)
# For fitness certificate
openssl req -x509 -newkey rsa:4096 -keyout fitness-key.pem \
  -out fitness-cert.pem -days 365 -nodes \
  -subj "/CN=fitness.medishift.co.in"

openssl pkcs12 -export \
  -out fitness.pfx \
  -inkey fitness-key.pem \
  -in fitness-cert.pem \
  -passout pass:Password123

# For organic certificate
openssl req -x509 -newkey rsa:4096 -keyout organic-key.pem \
  -out organic-cert.pem -days 365 -nodes \
  -subj "/CN=organic.medishift.co.in"

openssl pkcs12 -export \
  -out organic.pfx \
  -inkey organic-key.pem \
  -in organic-cert.pem \
  -passout pass:Password123

# Option B: Real certificates (Let's Encrypt)
# Use certbot to get certificates then convert to .pfx
```

### Step 3: Update terraform.tfvars
```hcl
# Edit these values in terraform.tfvars
resource_group_name = "HostRouting-RG"
location            = "Central India"
admin_password      = "YourSecurePassword@123"
fitness_hostname    = "fitness.yourdomain.com"
organic_hostname    = "organic.yourdomain.com"
fitness_pfx_path    = "path/to/fitness.pfx"
organic_pfx_path    = "path/to/organic.pfx"
pfx_password        = "YourPfxPassword"
```

### Step 4: Login to Azure
```bash
az login
az account show
```

### Step 5: Initialize Terraform
```bash
terraform init
```

### Step 6: Validate configuration
```bash
terraform validate
```

### Step 7: Preview changes
```bash
terraform plan
```

### Step 8: Deploy
```bash
terraform apply
# Type 'yes' when prompted
```

### Step 9: Note the outputs
```bash
# After apply completes you will see:
# appgw_public_ip     = "20.x.x.x"
# fitness_vm_private_ip = "10.0.1.x"
# organic_vm_private_ip = "10.0.2.x"
# fitness_url         = "https://fitness.medishift.co.in"
# organic_url         = "https://organic.medishift.co.in"
```

---

## SSL Certificates Setup

### Using Let's Encrypt (Production)
```bash
# Install certbot
sudo apt-get install certbot

# Get certificate (run on a machine where you control DNS)
certbot certonly --manual --preferred-challenges dns \
  -d fitness.medishift.co.in

certbot certonly --manual --preferred-challenges dns \
  -d organic.medishift.co.in

# Convert to .pfx format (required by Azure Application Gateway)
openssl pkcs12 -export \
  -out fitness.pfx \
  -inkey /etc/letsencrypt/live/fitness.medishift.co.in/privkey.pem \
  -in /etc/letsencrypt/live/fitness.medishift.co.in/fullchain.pem \
  -passout pass:YourPassword

openssl pkcs12 -export \
  -out organic.pfx \
  -inkey /etc/letsencrypt/live/organic.medishift.co.in/privkey.pem \
  -in /etc/letsencrypt/live/organic.medishift.co.in/fullchain.pem \
  -passout pass:YourPassword
```

---

## DNS Configuration

### After terraform apply completes:

**Step 1:** Get the Application Gateway Public IP from terraform output
```bash
terraform output appgw_public_ip
# Example output: 20.219.x.x
```

**Step 2:** Login to GoDaddy (or your DNS provider)

**Step 3:** Add A Records
```
Type    Name       Value           TTL
────    ────────   ─────────────   ───
A       fitness    20.219.x.x      600
A       organic    20.219.x.x      600
```

**Step 4:** Wait for DNS propagation (5-15 minutes)
```bash
# Check if DNS has propagated
nslookup fitness.medishift.co.in
nslookup organic.medishift.co.in

# Or use online tool: https://dnschecker.org
```

**Step 5:** Wait for cloud-init to complete (10-15 more minutes)
```bash
# VMs are still installing MongoDB + Node.js + cloning repo
# This takes 10-15 minutes after VM is created
```

**Step 6:** Test in browser
```
https://fitness.medishift.co.in  →  Should show Fitness Tracker App
https://organic.medishift.co.in  →  Should show Organic Ghee Store
http://fitness.medishift.co.in   →  Should redirect to HTTPS automatically
```

---

## Outputs

After `terraform apply` completes successfully:

```bash
resource_group_name   = "HostRouting-RG"
vnet_name             = "HostRouting-VNet"
fitness_vm_private_ip = "10.0.1.4"
organic_vm_private_ip = "10.0.2.4"
appgw_public_ip       = "20.219.x.x"     ← Add this to GoDaddy DNS
fitness_url           = "https://fitness.medishift.co.in"
organic_url           = "https://organic.medishift.co.in"
```

---

## Troubleshooting

### 502 Bad Gateway Error
```
Cause  : VMs are still running cloud-init bootstrap
Fix    : Wait 10-15 minutes then refresh
```

```bash
# To check bootstrap progress - use Azure Serial Console
# Portal → VM-Fitness → Serial Console
cat /var/log/bootstrap.log
```

### App Not Starting
```bash
# Check PM2 status
pm2 status
pm2 logs fittrack-pro
pm2 logs organic-ghee

# Check Nginx
systemctl status nginx
cat /var/log/nginx/fittrack-error.log

# Check MongoDB
systemctl status mongod
```

### DNS Not Resolving
```bash
# Check DNS propagation
nslookup fitness.medishift.co.in 8.8.8.8
# Visit: https://dnschecker.org
```

### Application Gateway Provisioning Failed
```bash
# Common causes:
# 1. AppGW subnet has other resources (must be dedicated)
# 2. GatewayManager NSG rule missing (65200-65535)
# 3. TLS policy deprecated (fixed with AppGwSslPolicy20220101)
# 4. PFX certificate path wrong or password incorrect
```

### VM Size Not Available
```bash
# Check available sizes in your region
az vm list-skus \
  --location centralindia \
  --size Standard_B \
  --output table

# Alternative sizes to try in terraform.tfvars:
# vm_size = "Standard_B2ms"
# vm_size = "Standard_D2s_v3"
```

### Terraform State Issues
```bash
# Fresh start - destroy and recreate
terraform destroy
terraform apply

# Or refresh state
terraform refresh
```

---

## Cleanup

```bash
# Destroy ALL resources created by this Terraform
# This will delete VMs, AppGW, VNet, NSGs, NAT Gateway etc.
terraform destroy

# Type 'yes' when prompted

# Verify in Azure Portal that HostRouting-RG is deleted
```

> ⚠️ **Warning:** `terraform destroy` permanently deletes all resources and data. Make sure you have backups of any important data before running this command.

---

## Important Notes

```
1. terraform.tfvars contains passwords - never share publicly
2. .pfx certificate files contain private keys - never share publicly
3. VMs have NO public IP - you cannot SSH directly
4   Use Azure Bastion or Serial Console for VM access
5. cloud-init takes 10-15 minutes - 502 errors are normal during this time
6. Standard_B2s minimum VM size - smaller sizes will OOM crash
7. AppGateway-Subnet must be dedicated - no other resources allowed
8. GatewayManager NSG rule is mandatory for AppGW to work
9. TLS policy AppGwSslPolicy20220101 required - older policies deprecated
10. NAT Gateway must be created BEFORE VMs (handled by depends_on)
```

---

## Technologies Used

| Technology | Version | Purpose |
|------------|---------|---------|
| Terraform | >= 1.3.0 | Infrastructure as Code |
| Azure Provider | ~> 3.90.0 | Azure resource management |
| Ubuntu | 22.04 LTS | VM Operating System |
| Node.js | 20.x | Application runtime |
| MongoDB | 7.0 | Database |
| PM2 | Latest | Node.js process manager |
| Nginx | Latest | Reverse proxy |
| Azure AppGW | WAF_v2 | Load balancer + WAF + SSL |
| OWASP | 3.2 | WAF ruleset |

---

*Created as part of Azure Cloud Track - Day 14*
*Topic: Host-Based Routing with Azure Application Gateway WAF v2*
