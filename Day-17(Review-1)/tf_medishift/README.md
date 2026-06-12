# MediShift - Automated Production-Grade Azure Infrastructure Deployment

Welcome to the **MediShift Infrastructure** project. This repository contains the complete, production-grade, and fully modular **Terraform** configuration required to deploy the **MediShift Healthcare Staff & Shift Management System** on **Microsoft Azure**.

This deployment strictly avoids containerization (no Docker, no Kubernetes) and implements a high-availability, fully automated, native Linux process execution model. The infrastructure includes an Azure Application Gateway (WAF_v2), a Virtual Machine Scale Set (VMSS) for the React frontend SPA, a standalone VM for the Express backend microservices, and a secure VNet-integrated Azure Database for PostgreSQL Flexible Server.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Solution Architecture](#2-solution-architecture)
3. [Architecture & Request Flow Details](#3-architecture--request-flow-details)
4. [Infrastructure Details](#4-infrastructure-details)
5. [Terraform Project Structure](#5-terraform-project-structure)
6. [Deployment Workflow & Prerequisites](#6-deployment-workflow--prerequisites)
7. [Automated Provisioning & App Deployment](#7-automated-provisioning--app-deployment)
8. [How to Run the Project Properly](#8-how-to-run-the-project-properly)
9. [Security Considerations](#9-security-considerations)
10. [Scalability & Production Readiness](#10-scalability--production-readiness)
11. [Troubleshooting Guide](#11-troubleshooting-guide)
12. [Future Improvements](#12-future-improvements)
13. [Conclusion](#13-conclusion)

---

## 1. Project Overview

### Project Purpose
MediShift is a mission-critical healthcare application designed to manage staff schedules, shift rotations, and leave requests for medical institutions. Because healthcare services operate 24/7, the application demands a resilient, secure, and highly available hosting environment that guarantees maximum uptime.

### Problem Statement
Deploying a multi-tier microservices application in an enterprise cloud environment usually introduces challenges around:
- **Port conflicts & service discovery** when multiple Node.js applications are co-located.
- **VNet integration** and secure private access for databases.
- **Resource limit quotas** in development or standard Azure subscriptions.
- **Bootstrapping delays** and cold-start health check failures at the load balancer.
- **Secrets leaks** when injecting environment variables and database connection strings.

### Solution Architecture
The architecture is designed to map a secure, non-containerized, fully automated native Linux model:
- **Web Tier**: Virtual Machine Scale Set (VMSS) serving the React 18 SPA statically via Nginx.
- **Application Tier**: A standalone VM hosting 4 Express backend microservices (Auth, Staff, Shift, and Leave) running natively under the **PM2** process manager.
- **Database Tier**: Fully managed **Azure Database for PostgreSQL Flexible Server** isolated inside a delegated VNet subnet.
- **Ingress & Security**: An **Azure Application Gateway (WAF_v2)** providing WAF protection and pure **HTTP Path-Based Routing** to map the client requests dynamically.

### Key Features
- **100% Non-Containerized**: Relies strictly on native Linux execution using systemd, Nginx, and PM2.
- **No Expiring SAS URLs**: Uses public GitHub fetching during VM provisioning for reproducible CI/CD delivery.
- **Zero-Downtime Health Probing**: Immediate Nginx bootup on VM creation serving a status loading page, satisfying Application Gateway health checks and preventing `502 Bad Gateway` timeouts.
- **Subscription Core Quota Compliant**: Tailored to work flawlessly under strict **4-core regional vCPU limitations** by using `Standard_B2as_v2` and `Standard_B1ms` SKUs intelligently.
- **VNet-Delegated Postgres Database**: Complete data isolation with no public IP exposure.

### Technologies Used
* **Infrastructure as Code (IaC)**: Terraform (>= 1.3.0)
* **Cloud Platform**: Microsoft Azure (azurerm provider)
* **Web Server & Reverse Proxy**: Nginx
* **Process Manager**: PM2 (Process Manager 2)
* **Backend Runtime**: Node.js v20.x, Express.js, Sequelize ORM
* **Frontend Runtime**: React 18 SPA, Axios
* **Database**: Managed PostgreSQL v15

---

## 2. Solution Architecture

The deployment architecture is fully aligned with the Microsoft Azure Cloud Adoption Framework (CAF):

```
                        +---------------------------------------+
                        |               INTERNET                |
                        +---------------------------------------+
                                            |
                                    HTTP/HTTPS Ingress
                                            v
                        +---------------------------------------+
                        |        Application Gateway (WAF_v2)    |
                        +---------------------------------------+
                                   /                 \
                     Path: /*     /                   \  Path: /api/*
                                 /                     \
                                v                       v
                  +--------------------------+    +--------------------------+
                  |      Frontend VMSS       |    |     Microservices VM     |
                  |     (React SPA / Nginx)  |    | (Nginx -> Node.js / PM2) |
                  |    Subnet: 10.0.2.0/24   |    |    Subnet: 10.0.3.0/24   |
                  +--------------------------+    +--------------------------+
                               |                               |
                               | (Outbound NAT)                | (Port 5432 - VNet Link)
                               v                               v
                  +--------------------------+    +--------------------------+
                  |       NAT Gateway        |    |    PostgreSQL Flexible   |
                  |   Provides Outbound Only |    |   VNet-Integrated DB     |
                  |     Internet for Builds  |    |    Subnet: 10.0.4.0/24   |
                  +--------------------------+    +--------------------------+
```

---

## 3. Architecture & Request Flow Details

### Detailed Request Walkthrough
1. **Client Request Ingress**: A user accesses the application at `http://medishift.co.in/`.
2. **Load Balancing (Path-Based Routing)**: The request hits the **Azure Application Gateway**. The Gateway WAF examines the HTTP request and checks the URL path:
   - **Static Frontend Routing**: If the path matches `/*` (e.g. `/`, `/login`, `/admin/dashboard`), the request is routed to the **Frontend VMSS Backend Pool** on port 80. Nginx on the VMSS serves the static React build files.
   - **Backend API Routing**: If the path matches `/api/*` (e.g. `/api/auth/login`, `/api/staff`), the request bypasses the frontend and is routed directly to the **Microservices VM Backend Pool** on port 80.
3. **Local Reverse Proxy Routing**: On the **Microservices VM**, the request is received by a local Nginx proxy listening on port 80. This proxy checks the sub-route:
   - `/api/auth/*` is reverse-proxied internally to localhost port **3001** (Auth Service).
   - `/api/departments/*` and `/api/staff/*` are reverse-proxied internally to localhost port **3002** (Staff Service).
   - `/api/shifts/*` is reverse-proxied internally to localhost port **3003** (Shift Service).
   - `/api/leaves/*` is reverse-proxied internally to localhost port **3004** (Leave Service).
4. **Database Communication**: Each microservice utilizes Sequelize ORM to execute CRUD operations on the VNet-Delegated **Azure Database for PostgreSQL**. The connection remains isolated inside the private virtual network.

---

## 4. Infrastructure Details

| Resource Component | Subnet Range | Purpose |
| :--- | :--- | :--- |
| **AppGateway-Subnet** | `10.0.1.0/24` | Hosts the WAF_v2 Application Gateway for SSL/HTTP Ingress. |
| **Frontend-Subnet** | `10.0.2.0/24` | Hosts the `Frontend-VMSS` Scale Set serving the React SPA on Port 80. |
| **Microservices-Subnet**| `10.0.3.0/24` | Hosts the single `VM-Microservices` running all 4 backend daemons under PM2. |
| **AzurePostgres-Subnet**| `10.0.4.0/24` | Delegated to `Microsoft.DBforPostgreSQL/flexibleServers` for managed database isolation. |
| **AzureBastionSubnet** | `10.0.5.0/24` | Dedicated subnet for Azure Bastion to secure SSH management. |

### Availability and Scaling
- **VMSS Scalability**: The frontend uses a Virtual Machine Scale Set configured with a **Manual** upgrade mode. Manual upgrade ensures that during deployment and cold boots, instances can take their time to run the cloud-init bootstrap pipeline and compile the React SPA without triggering rolling upgrade failures.
- **Burstable VMs (`Standard_B2as_v2`)**: Utilizes standard, cost-efficient burstable AMD sizes providing **4 GiB RAM**. This memory footprint prevents out-of-memory errors when building React or starting multiple Node.js runtimes.

---

## 5. Terraform Project Structure

The project code is divided into standard, reusable, and encapsulated modules:

```
tf_medishift/
├── main.tf                 # Global orchestrator that connects all modules
├── providers.tf            # Configures Azure and hashicorp standard providers
├── variables.tf            # Declares all global input variables
├── outputs.tf              # Returns public IPs, endpoints, and next steps
├── locals.tf               # Defines project tags and default JWT tokens
├── terraform.tfvars        # User-customized parameters (region, sizes, quotas)
├── modules/
│   ├── resource_group/     # Standardized Resource Group resource
│   ├── networking/         # VNet, Subnets, NAT Gateway, Bastion, NSGs, Private DNS
│   ├── security/           # User-Assigned Managed Identity configuration
│   ├── storage/            # Backup Blob Storage account & container resources
│   ├── database/           # PostgreSQL Flexible Server & database resource
│   ├── compute/            # Stands up standalone backend VM & Frontend VMSS
│   └── application_gateway/# Configures WAF_v2 and path-based routing rules
└── scripts/
    ├── frontend-bootstrap.sh.tpl      # Installs Nginx/Node.js, clones Git, compiles React
    └── microservices-bootstrap.sh.tpl  # Installs PM2/Node/Nginx, clones Git, injects PM2 env variables
```

---

## 6. Deployment Workflow & Prerequisites

### Prerequisites
1. **Azure Subscription**: An active Azure subscription (with vCPU quota available).
2. **Azure CLI**: Version >= 2.40.0 installed locally.
3. **Terraform CLI**: Version >= 1.3.0 installed locally.

### Authentication Steps
Before initializing Terraform, authenticate with Azure using your terminal:
```bash
az login
```
If you have multiple subscriptions, set the active subscription:
```bash
az account set --subscription "<your-subscription-id>"
```

---

## 7. Automated Provisioning & App Deployment

Executing `terraform apply` kicks off a 100% automated, zero-touch bootstrapping process:

### Startup Sequence & Health Probe Optimization
1. **Infrastructure Creation**: Azure sets up networking, subnets, database, NAT Gateway, Bastion, VM, and VMSS.
2. **Immediate Nginx Startup (Instant Health)**: 
   - During the first 1-2 minutes of the VM boot, Nginx is installed immediately.
   - An elegant placeholder page (`MediShift is Provisioning...`) is written to `/var/www/html/index.html`.
   - Nginx starts serving this page immediately on port 80.
   - **Why this is critical**: The Application Gateway probes `/` on port 80. Because Nginx responds immediately with a `200 OK` serving the loading page, the Application Gateway marks the backend as **Healthy** within the first few minutes, completely avoiding standard `502 Bad Gateway` cold-start timeouts.
3. **Background Build Pipeline**:
   - The VM/VMSS clones the codebase from: `https://github.com/MediShift-devops-project/MediShift_v1.git`.
   - Frontend runs `npm install` and compiles the React SPA via `npm run build`.
   - Backend VM runs `npm install` for the four backend folders sequentially.
4. **PM2 Process Injection**:
   - The Express apps do **not** use the `dotenv` library to read `.env` files. To overcome this, the bootstrap script **prepends all environment variables directly to the PM2 start commands**:
     ```bash
     PORT=3001 DATABASE_URL='...' JWT_SECRET='...' pm2 start src/index.js --name 'auth-service'
     ```
   - Prepending the variables forces the Linux OS to register them natively inside Node.js's `process.env`.
   - PM2 automatically registers and persists these parameters across service restarts and VM reboots.
5. **Production Swap**:
   - On the frontend VMSS, once `npm run build` completes, the script swaps out the loading page with the compiled React assets in `/var/www/html/`.
   - The application becomes immediately responsive to client actions.

---

## 8. How to Run the Project Properly

Follow this exact sequence of commands inside the `tf_medishift/` root directory to deploy the project:

### 1. Initialize Terraform
```bash
terraform init
```
* **What it does**: Downloads the required Terraform providers (`azurerm`, `random`, `archive`) and initializes the module registry.
* **Expected Output**: `Terraform has been successfully initialized!`

### 2. Validate Configuration
```bash
terraform validate
```
* **What it does**: Performs a static syntax check on all modules and root Terraform files.
* **Expected Output**: `Success! The configuration is valid.`

### 3. Generate Execution Plan
```bash
terraform plan
```
* **What it does**: Compiles the desired infrastructure state and compares it with your current Azure subscription state, highlighting resources to create, modify, or destroy.

### 4. Deploy Infrastructure
```bash
terraform apply --auto-approve
```
* **What it does**: Deploys the resources on Azure. 
* **Expected Output**: Generates the IP outputs and outputs the standard `Next Steps` summary.

---

## 9. Security Considerations

- **Strict Network Isolation**:
  - The PostgreSQL database has **no public IP**. It communicates exclusively inside the private delegated subnet.
  - The Virtual Machines have no public IPs mapped directly to their interfaces (except the Bastion PIP). Outbound internet access is managed via the **NAT Gateway**.
- **Network Security Groups (NSGs)**:
  - App Gateway only allows port 80/443 and GatewayManager inbound.
  - VMSS only allows port 80 inbound from the App Gateway Subnet CIDR.
  - Backend VM only allows ports 80, 3001-3004 inbound from the App Gateway Subnet CIDR.
  - PostgreSQL subnet only allows port 5432 inbound from the Microservices Subnet CIDR.
  - SSH (port 22) is blocked from the internet and only allowed inbound from the **Bastion Subnet CIDR**.
- **No Embedded Credentials**: Database passwords and JWT keys are handled as sensitive Terraform inputs and injected directly into PM2 environments during the provisioning run.

---

## 10. Scalability & Production Readiness

### Horizontal Scaling
The frontend web tier is deployed as an **Azure Virtual Machine Scale Set (VMSS)**. To scale out when user load increases:
1. Increase the `instances` attribute or configure scale-out policies in Azure.
2. The newly provisioned instances automatically register with the Application Gateway's `FrontendBackendPool` on boot.
3. Traffic is instantly load-balanced across the new servers.

### High Availability
- **Load Balancing**: Application Gateway acts as a highly resilient layer-7 load balancer.
- **Automatic Health Probes**: Faulty instances are automatically removed from the backend pool, preventing user requests from failing.

---

## 11. Troubleshooting Guide

### 1. 502 Bad Gateway Immediately After Apply
- **Reason**: The VM/VMSS is still running the cloud-init bootstrap script (cloning the repo, running `npm install`, compiling static React assets).
- **Fix**: Wait **3-5 minutes** and refresh the browser. The Application Gateway will mark the backends healthy once Nginx starts.

### 2. Quota Core Limit Exceeded
- **Reason**: Standard developer subscriptions are limited to **4 vCPUs** in the `Central India` region.
- **Fix**: Ensure `vm_size = "Standard_B2as_v2"` and `frontend_instances_count = 1` are set inside `terraform.tfvars`. This keeps your total cores exactly at 4 (2 for VM, 2 for VMSS) and avoids quota violations.

### 3. Database Connection Failure (`connect ECONNREFUSED`)
- **Reason**: The application processes are trying to connect to a local PostgreSQL instance on `127.0.0.1:5432` instead of the managed Azure PostgreSQL server. This happens if Node.js did not see the injected `DATABASE_URL` environment variable.
- **Fix**: Check `pm2 list` and `pm2 logs` on the **VM-Microservices** instance. Ensure the bootstrap script has prepended the variables directly onto the PM2 launch commands inside `microservices-bootstrap.sh.tpl`.

---

## 12. Future Improvements

1. **Dockerization / Container Migration**: Migrating the microservices to Docker containers and deploying them via Azure Container Apps or Azure Kubernetes Service (AKS) to optimize resource density.
2. **CI/CD Integration**: Creating a GitHub Actions pipeline to automatically run `terraform apply` on pushes to the `main` branch.
3. **SSL Termination**: Binding custom domains and configuring TLS/HTTPS certificates on the Application Gateway.
4. **Monitoring & Alerts**: Integrating Azure Monitor, Log Analytics, and Application Insights to monitor PM2 process logs and server health parameters natively.

---

## 13. Conclusion

The MediShift Azure Infrastructure project represents a highly optimized, production-grade cloud topology built on strict enterprise guidelines:
- **100% Non-Containerized Native Linux Process Architecture** (using Nginx, PM2, and systemd).
- **Secure Network Separation** (isolating database networks via VNet delegation and Private DNS).
- **Auto-Provisioning Integrity** (bootstrapping Nginx immediately to satisfy Application Gateway health probes).
- **Cost & Quota Efficiency** (using burstable AMD VM sizes tailored to regional cores limitations).

This project is fully ready for academic, professional portfolio, or developer demonstration purposes, showcasing advanced DevOps engineering and Cloud Architecture best practices on Microsoft Azure.
