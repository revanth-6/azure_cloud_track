# 🧈 Organic Ghee — Azure VMSS Infrastructure with Terraform

This project deploys a **complete cloud infrastructure** on Microsoft Azure
for the **Organic Ghee** web application using **Terraform**.
Everything is automated — from networking to auto-scaling to email alerts.

---

## 📋 Table of Contents

- [What This Project Does](#what-this-project-does)
- [Architecture Overview](#architecture-overview)
- [How Data Flows](#how-data-flows)
- [Project Structure](#project-structure)
- [How Terraform Files Connect](#how-terraform-files-connect)
- [Modules Explained](#modules-explained)
- [Prerequisites](#prerequisites)
- [How to Deploy](#how-to-deploy)
- [How to Test](#how-to-test)
- [How to Destroy](#how-to-destroy)
- [Common Errors and Fixes](#common-errors-and-fixes)

---

## 🌟 What This Project Does

When you run this Terraform code, it automatically creates:

```
✅ A Virtual Network (VNet) with a Subnet
✅ A Network Security Group (Firewall rules)
✅ A Load Balancer with Public IP
✅ A VM Scale Set (VMSS) with 2 Ubuntu VMs
✅ Auto Scaling (adds/removes VMs based on CPU usage)
✅ Azure Service Bus (message queue for alerts)
✅ Azure Logic App (bridges Monitor alerts to Service Bus)
✅ Azure Monitor (watches CPU and fires alerts)
✅ Email Notifications when CPU goes high
```

The VMs automatically:
```
✅ Install MongoDB (database)
✅ Install Node.js (runtime)
✅ Install PM2 (process manager)
✅ Install Nginx (web server / reverse proxy)
✅ Clone the Organic Ghee app from GitHub
✅ Start the app automatically
```

---

## 🏗️ Architecture Overview

```
                        INTERNET
                            │
                            │ HTTP (Port 80)
                            ▼
                 ┌─────────────────────┐
                 │   Public IP Address  │
                 │   (Static IP)        │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Load Balancer      │
                 │   (Distributes       │
                 │    traffic evenly)   │
                 │                      │
                 │  Port 80 → Port 5656 │
                 └──────────┬──────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
   ┌─────────────────┐         ┌─────────────────┐
   │   VM Instance 0  │         │   VM Instance 1  │
   │   Ubuntu 22.04   │         │   Ubuntu 22.04   │
   │   2 vCPU / 4GB   │         │   2 vCPU / 4GB   │
   │   30GB Disk      │         │   30GB Disk      │
   │                  │         │                  │
   │  ┌────────────┐  │         │  ┌────────────┐  │
   │  │   Nginx    │  │         │  │   Nginx    │  │
   │  │  (Port 80) │  │         │  │  (Port 80) │  │
   │  └─────┬──────┘  │         │  └─────┬──────┘  │
   │        │         │         │        │         │
   │        ▼         │         │        ▼         │
   │  ┌────────────┐  │         │  ┌────────────┐  │
   │  │  Node App  │  │         │  │  Node App  │  │
   │  │ (Port 5656)│  │         │  │ (Port 5656)│  │
   │  └─────┬──────┘  │         │  └─────┬──────┘  │
   │        │         │         │        │         │
   │        ▼         │         │        ▼         │
   │  ┌────────────┐  │         │  ┌────────────┐  │
   │  │  MongoDB   │  │         │  │  MongoDB   │  │
   │  │(Port 27017)│  │         │  │(Port 27017)│  │
   │  └────────────┘  │         │  └────────────┘  │
   └─────────────────┘         └─────────────────┘
              │                           │
              └─────────────┬─────────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Autoscaling Group  │
                 │   Min: 2 VMs         │
                 │   Max: 5 VMs         │
                 │   CPU > 70% → Add VM │
                 │   CPU < 30% → Remove │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Azure Monitor      │
                 │   Watches CPU usage  │
                 │   Fires alert if     │
                 │   CPU > 70%          │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Action Group       │
                 │   (What to do when   │
                 │    alert fires)      │
                 │                      │
                 │  ┌───────────────┐   │
                 │  │  Send Email   │   │
                 │  └───────────────┘   │
                 │  ┌───────────────┐   │
                 │  │Call Logic App │   │
                 │  │  (Webhook)    │   │
                 │  └───────┬───────┘   │
                 └──────────┼──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Azure Logic App    │
                 │   (HTTP Trigger)     │
                 │   Receives webhook   │
                 │   Forwards message   │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │  Azure Service Bus   │
                 │                      │
                 │  Topic (Publisher)   │
                 │  cpu-alert-topic     │
                 │         │            │
                 │         ▼            │
                 │  Subscription        │
                 │  (Subscriber)        │
                 │  email-alert-sub     │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   📧 Your Email      │
                 │   Alert Received!    │
                 │   CPU is High on     │
                 │   VMSS              │
                 └─────────────────────┘
```

---

## 🔄 How Data Flows

### 1. Normal Traffic Flow (User visits website)
```
User opens browser
      │
      │ types http://<public-ip>
      ▼
Load Balancer receives request on Port 80
      │
      │ forwards to one of the VMs on Port 5656
      ▼
Nginx on VM receives request
      │
      │ proxies to Node.js app on Port 5656
      ▼
Node.js app processes request
      │
      │ reads/writes data
      ▼
MongoDB database (on same VM)
      │
      │ returns data to Node.js
      ▼
Response sent back to user
```

### 2. Alert Flow (CPU goes high)
```
Many users hit the website at same time (stress test)
      │
      ▼
CPU on VMs goes above 70%
      │
      ▼
Azure Monitor detects this after 5 minutes
      │
      ▼
Alert Rule fires
      │
      ├──────────────────────────────────┐
      │                                  │
      ▼                                  ▼
Direct Email sent                  Webhook called
to your inbox                      (Logic App URL)
                                         │
                                         ▼
                                   Logic App receives
                                   the alert payload
                                         │
                                         ▼
                                   Publishes message
                                   to Service Bus Topic
                                         │
                                         ▼
                                   Subscription picks
                                   up the message
```

### 3. Autoscaling Flow (Adding/Removing VMs)
```
CPU > 70% for 5 minutes
      │
      ▼
Autoscale rule triggers
      │
      ▼
New VM instance created automatically
      │
      ▼
Bootstrap script runs on new VM
(installs everything automatically)
      │
      ▼
New VM joins Load Balancer backend pool
      │
      ▼
Traffic now distributed across 3 VMs
      │
      ▼
CPU drops (load is shared)


When load stops:
CPU < 30% for 5 minutes
      │
      ▼
Autoscale removes extra VM
      │
      ▼
Back to minimum 2 VMs
```

---

## 📁 Project Structure

```
project/
│
├── main.tf              ← Master file — calls all modules
├── variables.tf         ← Declares all input variables
├── outputs.tf           ← What to show after deployment
├── terraform.tfvars     ← Your actual values (IPs, names, etc.)
├── bootstrap.sh         ← Script that runs on each VM at startup
│
└── modules/             ← Each folder = one piece of infrastructure
    │
    ├── resource_group/  ← Creates the Resource Group
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── networking/      ← Creates VNet and Subnet
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── nsg/             ← Creates Firewall rules
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── load_balancer/   ← Creates Load Balancer and Public IP
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vmss/            ← Creates VM Scale Set
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── autoscaling/     ← Creates scaling rules
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── service_bus/     ← Creates Service Bus, Topic, Subscription
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── logic_app/       ← Creates Logic App (webhook bridge)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── monitor/         ← Creates alerts and action groups
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 🔗 How Terraform Files Connect

This is the most important concept to understand.
Think of it like **function calls in programming**.

### The Big Picture

```
terraform.tfvars          ← You fill values here
      │
      │ values flow into
      ▼
variables.tf (root)       ← Declares what values are expected
      │
      │ passed into
      ▼
main.tf (root)            ← The MASTER file
      │                      Calls each module like a function
      │
      ├── calls module/resource_group  → creates RG
      │         │ outputs RG name, location, ID
      │         └──────────────────────────────────────┐
      │                                                 │
      ├── calls module/networking      → creates VNet   │
      │         │ receives RG name from resource_group  │
      │         │ outputs subnet_id                     │
      │         └──────────────────────┐               │
      │                                │               │
      ├── calls module/nsg             │               │
      │         │ receives subnet_id ──┘               │
      │         │ attaches NSG to subnet               │
      │                                                │
      ├── calls module/load_balancer                   │
      │         │ receives RG name ───────────────────┘
      │         │ outputs backend_pool_id
      │         │ outputs probe_id
      │         │ outputs lb_rule_id
      │         │ outputs public_ip
      │         └──────────────────────┐
      │                                │
      ├── calls module/vmss            │
      │         │ receives subnet_id   │
      │         │ receives backend_pool_id, probe_id,
      │         │ lb_rule_id from load_balancer ───────┘
      │         │ outputs vmss_id
      │         └──────────────────────┐
      │                                │
      ├── calls module/autoscaling     │
      │         │ receives vmss_id ────┘
      │
      ├── calls module/service_bus
      │         │ outputs connection_string
      │         │ outputs namespace_endpoint
      │         └──────────────────────┐
      │                                │
      ├── calls module/logic_app       │
      │         │ receives connection_string ──────────┘
      │         │ outputs webhook_url
      │         └──────────────────────┐
      │                                │
      └── calls module/monitor         │
                │ receives vmss_id     │
                │ receives webhook_url ┘
                │ creates alerts
                │ creates action group
```

### Simple Example — How subnet_id travels

```
Step 1: networking/main.tf creates the subnet
        resource "azurerm_subnet" "subnet" { ... }

Step 2: networking/outputs.tf exposes the ID
        output "subnet_id" {
          value = azurerm_subnet.subnet.id
        }

Step 3: root/main.tf receives it from networking module
        module "networking" {
          source = "./modules/networking"
          ...
        }
        # Now module.networking.subnet_id is available

Step 4: root/main.tf passes it to vmss module
        module "vmss" {
          source    = "./modules/vmss"
          subnet_id = module.networking.subnet_id  ← passed here
          ...
        }

Step 5: vmss/variables.tf declares it expects this value
        variable "subnet_id" {
          type = string
        }

Step 6: vmss/main.tf uses it
        network_interface {
          ip_configuration {
            subnet_id = var.subnet_id  ← used here
          }
        }
```

---

## 📦 Modules Explained

### 🗂️ resource_group
```
What it does : Creates a container for all resources
Why needed   : All Azure resources must live in a Resource Group
Inputs       : name, location, tags
Outputs      : resource_group_name, location, resource_group_id
```

### 🌐 networking
```
What it does : Creates Virtual Network and Subnet
Why needed   : VMs need a private network to communicate
Inputs       : resource_group_name, vnet_name, subnet_name,
               address spaces
Outputs      : vnet_id, subnet_id
```

### 🔒 nsg (Network Security Group)
```
What it does : Creates firewall rules
Why needed   : Controls what traffic is allowed in/out
Rules created:
  Port 22   → Allow SSH (to connect to VMs)
  Port 80   → Allow HTTP (web traffic)
  Port 5656 → Allow App (Node.js app)
Inputs       : resource_group_name, nsg_name, subnet_id
Outputs      : nsg_id
```

### ⚖️ load_balancer
```
What it does : Creates Public IP + Load Balancer
Why needed   : One IP for users, distributes traffic to VMs
How it works :
  User hits Port 80 on Public IP
  LB sends to Port 5656 on one of the VMs
  Health probe checks if VM is alive every 5 seconds
Inputs       : resource_group_name, lb_name, app_port
Outputs      : backend_pool_id, probe_id, lb_rule_id,
               public_ip_address
```

### 💻 vmss (Virtual Machine Scale Set)
```
What it does : Creates multiple VMs that can scale
Why needed   : Run the actual application
VM details   :
  OS       : Ubuntu 22.04 LTS
  Size     : Standard_B2als_v2 (2 vCPU, 4GB RAM)
  Disk     : 30GB
  Username : azureuser
Bootstrap   : Runs bootstrap.sh automatically on every VM
Inputs       : subnet_id, lb_backend_pool_id, lb_probe_id,
               lb_rule_id, bootstrap_script_base64
Outputs      : vmss_id, vmss_name

⚠️ Important: depends_on lb_rule_id
   VMSS waits for LB Rule to finish before starting
   This prevents health probe errors
```

### 📈 autoscaling
```
What it does : Adds or removes VMs based on CPU
Why needed   : Handle traffic spikes automatically
Rules        :
  CPU > 70% for 5 min → Add 1 VM (max 5)
  CPU < 30% for 5 min → Remove 1 VM (min 2)
Cooldown     : 5 minutes between each scale action
Inputs       : vmss_id, min, max, default instances,
               cpu thresholds
Outputs      : autoscale_setting_id
```

### 📨 service_bus
```
What it does : Creates a message queue system
Why needed   : Pub/Sub model for alert messages
Components   :
  Namespace    → Container for Service Bus
  Topic        → Channel where messages are published
  Subscription → Who receives the messages
How it works :
  Publisher (Monitor/Logic App) sends to Topic
  Subscriber (email system) reads from Subscription
Inputs       : namespace_name, topic_name, subscription_name
Outputs      : primary_connection_string, namespace_endpoint,
               topic_name
```

### ⚡ logic_app
```
What it does : Creates a workflow that bridges Monitor
               alerts to Service Bus
Why needed   : Azure Monitor cannot directly write to
               Service Bus — Logic App acts as bridge
How it works :
  1. Azure Monitor fires alert
  2. Calls Logic App via Webhook (HTTP POST)
  3. Logic App receives the payload
  4. Logic App sends message to Service Bus Topic
Inputs       : logic_app_name, servicebus_connection_string,
               servicebus_topic_name
Outputs      : webhook_url (used in Action Group)
```

### 🔔 monitor
```
What it does : Creates alert rules and notification setup
Why needed   : Watch CPU and notify when threshold crossed
Components   :
  Action Group    → What to do when alert fires
                    (send email + call webhook)
  Metric Alert    → Watch CPU > 70%
  Activity Alert  → Watch for scale out events
Inputs       : vmss_id, resource_group_id, alert_email,
               logic_app_webhook_url, cpu_threshold
Outputs      : action_group_id, alert_ids
```

---

## 🚀 bootstrap.sh Explained

This script runs **automatically on every VM** when it first starts.
It is passed to the VM via `custom_data` (base64 encoded).

```
bootstrap.sh execution order:

[1/10] Update system packages
       apt-get update && apt-get upgrade

[2/10] Install dependencies
       curl, wget, git, nginx, build-essential...

[3/10] Install MongoDB 7.0
       Add MongoDB repo → Install → Configure

[4/10] Configure & Start MongoDB
       Write /etc/mongod.conf
       systemctl enable mongod
       systemctl start mongod

[5/10] Install Node.js v20
       via NodeSource setup script

[6/10] Install PM2
       npm install -g pm2
       (PM2 keeps Node app running always)

[7/10] Clone Application from GitHub
       git clone https://github.com/...organic-ghee.git

[8/10] Install npm dependencies
       npm install inside app directory

[9/10] Create .env file
       PORT=5656
       MONGODB_URI=mongodb://127.0.0.1:27017/restorent

[10/10] Start app with PM2
        pm2 start src/app.js --name organic-ghee
        pm2 save
        pm2 startup (auto-start on reboot)

After all steps:
        Configure Nginx as reverse proxy
        Port 80 → Port 5656
        Health check
        Print final status
```

---

## ✅ Prerequisites

### 1. Install Required Tools

```bash
# Terraform
# Download from: https://developer.hashicorp.com/terraform/downloads

# Azure CLI
# Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Verify installations
terraform --version    # Should be >= 1.3.0
az --version           # Any recent version
```

### 2. Login to Azure

```bash
az login
# A browser window opens
# Login with your Azure account
```

### 3. Verify Subscription

```bash
az account show
# Note your subscription ID
```

---

## 🛠️ How to Deploy

### Step 1 — Clone This Repository

```bash
git clone <your-repo-url>
cd <repo-folder>
```

### Step 2 — Update terraform.tfvars

Open `terraform.tfvars` and fill in your values:

```hcl
# Change these values
resource_group_name          = "RG"
location                     = "Central India"
alert_email                  = "youremail@gmail.com"  ← Your email
servicebus_namespace_name    = "vmss-alerts-bus-yourname"  ← Must be unique
admin_password               = "YourStrongPassword@123"
```

### Step 3 — Initialize Terraform

```bash
terraform init
```

```
What this does:
- Downloads Azure provider plugin
- Sets up backend
- Prepares modules
```

### Step 4 — Preview Changes

```bash
terraform plan
```

```
What this does:
- Shows you EXACTLY what will be created
- Does NOT create anything yet
- Review the output carefully
```

### Step 5 — Deploy Everything

```bash
terraform apply
```

```
Type "yes" when prompted

What happens:
- Creates all 21 resources
- Takes about 5-10 minutes
- Shows outputs at the end
```

### Step 6 — Note the Outputs

```bash
# After apply completes
app_url                 = "http://x.x.x.x"
load_balancer_public_ip = "x.x.x.x"
vmss_name               = "Organic-Ghee-VMSS"
```

### Step 7 — Wait for Bootstrap

```
⏳ Wait 15 minutes for VMs to finish setup
   Then open: http://<app_url> in browser
```

---

## 🧪 How to Test

### Test App is Running
```bash
curl http://<load_balancer_public_ip>
# Should return HTML of Organic Ghee website
```

### Test Autoscaling with Apache Benchmark

```bash
# Install ab
sudo apt-get install apache2-utils -y

# Run from OUTSIDE Azure (your local machine)
# NOT from a VM inside the same VNet

# Baseline test
ab -n 100 -c 5 http://<public-ip>/

# Stress test (triggers autoscale)
ab -n 999999 -c 500 -t 600 http://<public-ip>/
```

### Watch Instances Scale Up
```bash
# In a separate terminal
watch -n 30 'az vmss list-instances \
  --resource-group RG \
  --name Organic-Ghee-VMSS \
  --output table'
```

---

## 💥 How to Destroy

```bash
# Destroys ALL resources
terraform destroy

# Type "yes" when prompted
# ⚠️ This deletes everything permanently
```

---

## ❗ Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `IPv4BasicSkuPublicIpCountLimitReached` | Basic IP not allowed | Use `sku = "Standard"` in load_balancer |
| `SkuNotAvailable` | VM size not in region | Change `vm_sku` in tfvars |
| `WorkflowStandard quota = 0` | No quota for Logic App Standard | Use `azurerm_logic_app_workflow` (Consumption) |
| `CannotUseInactiveHealthProbe` | VMSS started before LB Rule | Add `depends_on = [var.lb_rule_id]` in vmss |
| `Unrecognized option: storage.journal` | MongoDB 7.0 removed this | Remove `journal:` block from mongod.conf |
| `ab timeout error` | Test VM inside same VNet | Run ab from outside Azure (local machine) |
| Provider registration error | No permission to register providers | Add `skip_provider_registration = true` |

---

## 📊 Resources Created (21 Total)

| # | Resource | Name | Purpose |
|---|----------|------|---------|
| 1 | Resource Group | RG | Container for everything |
| 2 | Virtual Network | VNet-1 | Private network |
| 3 | Subnet | Subnet-1 | VM subnet |
| 4 | NSG | VMSS-NSG | Firewall rules |
| 5 | NSG Association | - | Links NSG to Subnet |
| 6 | Public IP | LB-PublicIP | Entry point |
| 7 | Load Balancer | VMSS-BasicLB | Traffic distributor |
| 8 | LB Backend Pool | VMSS-Backend-Pool | Group of VMs |
| 9 | LB Health Probe | App-Health-Probe | VM health check |
| 10 | LB Rule | LB-Rule-80-to-5656 | Traffic routing |
| 11 | VMSS | Organic-Ghee-VMSS | VM Scale Set |
| 12 | Autoscale Setting | VMSS-Autoscale-Policy | Scaling rules |
| 13 | Service Bus NS | vmss-alerts-bus-* | Message broker |
| 14 | Service Bus Topic | cpu-alert-topic | Pub channel |
| 15 | SB Subscription | email-alert-sub | Sub channel |
| 16 | Logic App | vmss-alert-logicapp | Alert bridge |
| 17 | Logic App Trigger | http-trigger | Webhook receiver |
| 18 | Logic App Action | Send-To-ServiceBus | Forwards message |
| 19 | Action Group | VMSS-Alert-ActionGroup | Alert handler |
| 20 | Metric Alert | High-CPU-Alert | CPU monitor |
| 21 | Activity Alert | ScaleOut-Notification | Scale monitor |

---

## 🔑 Key Concepts for Beginners

### What is Terraform?
```
Terraform is Infrastructure as Code (IaC)
Instead of clicking in Azure Portal manually,
you write code to create resources.

Benefits:
- Repeatable (run same code = same result)
- Version controlled (track changes in Git)
- Fast (creates everything automatically)
- Destroyable (terraform destroy = clean slate)
```

### What is a Module?
```
A module is a reusable group of Terraform resources.
Think of it like a function in programming.

Without modules:          With modules:
main.tf = 1000 lines      main.tf = 100 lines
hard to read              easy to read
hard to reuse             reusable

Each module:
- Has its own main.tf (what to create)
- Has its own variables.tf (what inputs it needs)
- Has its own outputs.tf (what it gives back)
```

### What is variables.tf vs terraform.tfvars?
```
variables.tf    = DECLARES what variables exist
                  Like a form template

terraform.tfvars = FILLS IN the values
                   Like a filled form

Example:
variables.tf says:    variable "location" { type = string }
terraform.tfvars says: location = "Central India"
```

### What is outputs.tf?
```
After Terraform creates everything,
outputs.tf tells it what information to display.

Like a receipt after shopping.

Example output:
app_url = "http://74.225.147.216"
          ↑
          This is how you know your app's IP address
```

---

## 👨‍💻 Author

Built as part of Azure Cloud Infrastructure Lab
- App: Organic Ghee (Node.js + MongoDB)
- Infrastructure: Azure VMSS with Terraform
- Region: Central India
