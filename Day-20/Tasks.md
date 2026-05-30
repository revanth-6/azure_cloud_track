# Azure Infrastructure Implementation Tasks

## Fitness Tracker Application Deployment Guide

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Task List](#task-list)
4. [Detailed Implementation Steps](#detailed-implementation-steps)

---

## 🏗️ Architecture Overview

```text
👤 User Request
↓
🌐 Azure Front Door + CDN
↓
🛡️ Application Gateway + WAF
↓
📱 App Service (Blue-Green Deployment)
↓
🗄️ Azure Cosmos DB (MongoDB)
```

---

## ✅ Task List

### Phase 1: Foundation Setup

* [ ] Task 1: Create Azure Account
* [ ] Task 2: Create Resource Group

### Phase 2: Database Setup

* [ ] Task 3: Create Azure Cosmos DB (MongoDB API)
* [ ] Task 4: Create Database and Collection
* [ ] Task 5: Save Connection String

### Phase 3: Application Setup

* [ ] Task 6: Create App Service Plan
* [ ] Task 7: Create Web App (Node.js)
* [ ] Task 8: Configure Environment Variables
* [ ] Task 9: Set Startup Command
* [ ] Task 10: Create Staging Slot (Blue-Green)

### Phase 4: Network Setup

* [ ] Task 11: Create Virtual Network
* [ ] Task 12: Create Application Gateway Subnet
* [ ] Task 13: Create App Service Subnet

### Phase 5: Security Setup

* [ ] Task 14: Create Application Gateway
* [ ] Task 15: Configure WAF Policy
* [ ] Task 16: Configure Backend Pool
* [ ] Task 17: Configure Routing Rules

### Phase 6: CDN & Global Load Balancing

* [ ] Task 18: Create Azure Front Door
* [ ] Task 19: Configure CDN Endpoint
* [ ] Task 20: Configure Origin Group
* [ ] Task 21: Configure WAF Policy for Front Door

### Phase 7: Application Deployment

* [ ] Task 22: Setup GitHub Actions Workflow
* [ ] Task 23: Add Publish Profile Secret to GitHub
* [ ] Task 24: Deploy to Staging Slot
* [ ] Task 25: Test Staging Deployment
* [ ] Task 26: Swap Staging to Production (Blue-Green)
* [ ] Task 27: Test Production Deployment

### Phase 8: Verification

* [ ] Task 28: Test Full Architecture Flow
* [ ] Task 29: Verify Cosmos DB Connection
* [ ] Task 30: Verify Front Door URL

---

## 📝 Detailed Implementation Steps

---

## PHASE 1: Foundation Setup

---

### Task 1: Create Azure Account

URL: https://portal.azure.com

**Steps:**

1. Go to https://portal.azure.com
2. Click "Start free"
3. Sign up with Microsoft account
4. You get $200 free credits for 30 days

**Expected Result:**
✅ Azure Portal Dashboard visible
✅ Subscription created

```text
```

---

### Task 2: Create Resource Group

**Navigation:**
Azure Portal → Search "Resource Groups" → + Create

**Configuration:**

| Field               | Value             |
| ------------------- | ----------------- |
| Subscription        | Your subscription |
| Resource Group Name | `my-app-rg`       |
| Region              | `East US`         |

**Steps:**

1. Go to Azure Portal
2. Search "Resource Groups" in top search bar
3. Click "+ Create"
4. Fill in the configuration table above
5. Click "Review + Create"
6. Click "Create"

**Expected Result:**
✅ Resource Group "my-app-rg" created
✅ Region: East US

---

## PHASE 2: Database Setup

---

### Task 3: Create Azure Cosmos DB (MongoDB API)

**Navigation:**
Azure Portal → Search "Azure Cosmos DB" → + Create →
Azure Cosmos DB for MongoDB → Create →
Request Unit (RU) database account → Create

**Configuration:**

| Tab                 | Field               | Value                   |
| ------------------- | ------------------- | ----------------------- |
| Basics              | Subscription        | Your subscription       |
| Basics              | Resource Group      | `my-app-rg`             |
| Basics              | Account Name        | `my-mongo-cosmos-12345` |
| Basics              | Location            | `East US`               |
| Basics              | Capacity Mode       | `Serverless`            |
| Basics              | Version             | `7.0`                   |
| Global Distribution | Geo-Redundancy      | `Disable`               |
| Global Distribution | Multi-region Writes | `Disable`               |
| Networking          | Connectivity        | `All Networks`          |
| Backup              | Policy              | `Periodic`              |
| Backup              | Redundancy          | `Locally-redundant`     |
| Encryption          | Data Encryption     | `Service-managed key`   |

**Steps:**

1. Go to Azure Portal
2. Search "Azure Cosmos DB"
3. Click "+ Create"
4. Select "Azure Cosmos DB for MongoDB"
5. Click "Create" under "Request Unit (RU)"
6. Fill in configuration table above
7. Click "Review + Create"
8. Click "Create"
9. Wait 5-10 minutes

**Expected Result:**
✅ Cosmos DB Account created
✅ MongoDB Version: 7.0
✅ Capacity: Serverless

---

### Task 4: Create Database and Collection

**Navigation:**
Cosmos DB Account → Data Explorer → New Collection

**Configuration:**

| Field         | Value             |
| ------------- | ----------------- |
| Database ID   | `fitness-tracker` |
| Collection ID | `myAppCollection` |
| Shard Key     | `_id`             |

**Steps:**

1. Go to your Cosmos DB account
2. Click "Data Explorer" in left menu
3. Click "New Collection"
4. Fill in configuration above
5. Click "OK"

**Expected Result:**
✅ Database "fitness-tracker" created
✅ Collection "myAppCollection" created

---

### Task 5: Save Connection String

**Navigation:**
Cosmos DB Account → Connection Strings → Copy Primary

**Steps:**

1. Go to Cosmos DB account
2. Left menu → Click "Connection strings"
3. Copy "Primary Connection String"
4. Add database name to connection string:

**Format:**

Original:

```text
mongodb://account:password@account.mongo.cosmos.azure.com:10255/?ssl=true&...
```

Modified (add /fitness-tracker before ?):

```text
mongodb://account:password@account.mongo.cosmos.azure.com:10255/fitness-tracker?ssl=true&...
```

5. Save in Notepad for later use

**Expected Result:**
✅ Connection string saved
✅ Database name added to connection string

---

## PHASE 3: Application Setup

---

### Task 6 & 7: Create App Service Plan and Web App

**Navigation:**
Azure Portal → Search "App Services" → + Create → Web App

**Configuration:**

| Tab        | Field                 | Value                                  |
| ---------- | --------------------- | -------------------------------------- |
| Basics     | Subscription          | Your subscription                      |
| Basics     | Resource Group        | `my-app-rg`                            |
| Basics     | Name                  | `revanth-fitness`                      |
| Basics     | Publish               | `Code`                                 |
| Basics     | Runtime Stack         | `Node 20 LTS`                          |
| Basics     | Operating System      | `Linux`                                |
| Basics     | Region                | `East US`                              |
| Basics     | Linux Plan            | Create New → `my-app-service-plan`     |
| Basics     | Pricing Plan          | `Standard S1`                          |
| Deployment | Continuous Deployment | `Disable`                              |
| Networking | Public Access         | `On`                                   |
| Monitoring | App Insights          | `Yes` → Create New → `my-app-insights` |

**Steps:**

1. Go to Azure Portal
2. Search "App Services"
3. Click "+ Create" → "Web App"
4. Fill in configuration table above
5. For Pricing Plan → Click "Explore pricing plans" → Select "Standard S1"
6. Click "Review + Create"
7. Click "Create"
8. Wait 2-3 minutes

**Expected Result:**
✅ App Service "revanth-fitness" created
✅ Runtime: Node 20 LTS
✅ Plan: Standard S1
✅ App Insights enabled

---

### Task 8: Configure Environment Variables

**Navigation:**
App Service → Environment Variables → + Add

**Configuration:**

| Name             | Value                             |
| ---------------- | --------------------------------- |
| `PORT`           | `8080`                            |
| `HOST`           | `0.0.0.0`                         |
| `NODE_ENV`       | `production`                      |
| `MONGODB_URI`    | Your Cosmos DB connection string  |
| `JWT_SECRET`     | `fitness-tracker-secret-key-2024` |
| `SESSION_SECRET` | `fitness-session-secret-2024`     |

**Steps:**

1. Go to App Service "revanth-fitness"
2. Left menu → "Environment variables"
3. Click "+ Add" for EACH variable above
4. After adding ALL variables → Click "Apply"
5. Click "Confirm"
6. Wait for restart

> ⚠️ IMPORTANT: Must click both "Apply" AND "Confirm"!

**Expected Result:**
✅ All 6 environment variables saved
✅ App Service restarted

---

### Task 9: Set Startup Command

**Navigation:**
App Service → Configuration → General Settings → Startup Command

**Configuration:**

| Field           | Value                |
| --------------- | -------------------- |
| Startup Command | `node server/app.js` |

**Steps:**

1. Go to App Service "revanth-fitness"
2. Left menu → "Configuration"
3. Click "General settings" tab
4. Find "Startup Command" field
5. Type: `node server/app.js`
6. Click "Save"
7. Click "Continue"

**Expected Result:**
✅ Startup command set
✅ App uses node server/app.js to start

---

### Task 10: Create Staging Slot (Blue-Green)

**Navigation:**
App Service → Deployment Slots → + Add Slot

**Configuration:**

| Field               | Value             |
| ------------------- | ----------------- |
| Name                | `staging`         |
| Clone Settings From | `revanth-fitness` |

**Steps:**

1. Go to App Service "revanth-fitness"
2. Left menu → "Deployment slots"
3. Click "+ Add Slot"
4. Name: `staging`
5. Clone settings from: `revanth-fitness`
6. Click "Add"

**Also add environment variables to staging slot:**

1. Click on staging slot
2. Go to "Environment variables"
3. Add same variables as Task 8
4. Click "Apply" → "Confirm"

**Also set startup command for staging slot:**

1. Click on staging slot
2. Go to "Configuration" → "General settings"
3. Set Startup Command: `node server/app.js`
4. Click "Save"

**Expected Result:**
✅ Staging slot created
✅ Production URL: revanth-fitness.azurewebsites.net
✅ Staging URL: revanth-fitness-staging.azurewebsites.net
✅ Environment variables set on staging
✅ Startup command set on staging

---

## PHASE 4: Network Setup

---

### Task 11, 12 & 13: Create Virtual Network with Subnets

**Navigation:**
Azure Portal → Search "Virtual Networks" → + Create

**Configuration:**

| Tab          | Field          | Value             |
| ------------ | -------------- | ----------------- |
| Basics       | Subscription   | Your subscription |
| Basics       | Resource Group | `my-app-rg`       |
| Basics       | Name           | `my-app-vnet`     |
| Basics       | Region         | `East US`         |
| Security     | Azure Bastion  | `Disable`         |
| Security     | Azure DDoS     | `Disable`         |
| Security     | Azure Firewall | `Disable`         |
| IP Addresses | Address Space  | `10.0.0.0/16`     |

**Subnet 1 - Application Gateway:**

| Field            | Value                 |
| ---------------- | --------------------- |
| Name             | `appgw-subnet`        |
| Starting Address | `10.0.1.0`            |
| Subnet Size      | `/24 (256 addresses)` |

**Subnet 2 - App Service:**

| Field            | Value                 |
| ---------------- | --------------------- |
| Name             | `app-service-subnet`  |
| Starting Address | `10.0.2.0`            |
| Subnet Size      | `/24 (256 addresses)` |

**Steps:**

1. Go to Azure Portal
2. Search "Virtual Networks"
3. Click "+ Create"
4. Fill in Basics configuration
5. Go to IP Addresses tab
6. Delete default subnet if exists
7. Click "+ Add a subnet" → Fill Subnet 1 details → Click "Add"
8. Click "+ Add a subnet" → Fill Subnet 2 details → Click "Add"
9. Click "Review + Create"
10. Click "Create"

**Expected Result:**
✅ VNet "my-app-vnet" created
✅ Address Space: 10.0.0.0/16
✅ Subnet 1: appgw-subnet (10.0.1.0/24)
✅ Subnet 2: app-service-subnet (10.0.2.0/24)

---

## PHASE 5: Security Setup

---

### Task 14, 15, 16 & 17: Create Application Gateway + WAF

**Navigation:**
Azure Portal → Search "Application Gateways" → + Create

**Configuration:**

| Tab       | Field             | Value                          |
| --------- | ----------------- | ------------------------------ |
| Basics    | Subscription      | Your subscription              |
| Basics    | Resource Group    | `my-app-rg`                    |
| Basics    | Name              | `my-app-gateway`               |
| Basics    | Region            | `East US`                      |
| Basics    | Tier              | `WAF V2`                       |
| Basics    | Autoscaling       | `Yes`                          |
| Basics    | Min Instances     | `1`                            |
| Basics    | Max Instances     | `2`                            |
| Basics    | Availability Zone | `None`                         |
| Basics    | HTTP2             | `Enabled`                      |
| Basics    | Virtual Network   | `my-app-vnet`                  |
| Basics    | Subnet            | `appgw-subnet`                 |
| Frontends | IP Address Type   | `Public`                       |
| Frontends | Public IP         | Create New → `appgw-public-ip` |

**Backend Pool:**

| Field       | Value                 |
| ----------- | --------------------- |
| Name        | `app-service-backend` |
| Target Type | `App Services`        |
| Target      | `revanth-fitness`     |

**Backend Settings:**

| Field              | Value                      |
| ------------------ | -------------------------- |
| Name               | `http-backend-settings`    |
| Protocol           | `HTTPS`                    |
| Port               | `443`                      |
| Cookie Affinity    | `Disable`                  |
| Override Hostname  | `Yes`                      |
| Host Name Override | `Pick from backend target` |

**Routing Rule:**

| Field         | Value               |
| ------------- | ------------------- |
| Rule Name     | `http-routing-rule` |
| Priority      | `100`               |
| Listener Name | `http-listener`     |
| Frontend IP   | `Public`            |
| Protocol      | `HTTP`              |
| Port          | `80`                |
| Listener Type | `Basic`             |

**Steps:**

1. Go to Azure Portal
2. Search "Application Gateways"
3. Click "+ Create"
4. Fill in Basics configuration
5. Go to Frontends tab → Create new public IP
6. Go to Backends tab → Add backend pool
7. Go to Configuration tab → Add routing rule
8. Add listener details
9. Add backend target and settings
10. Click "Review + Create"
11. Click "Create"
12. Wait 15-20 minutes

**Configure WAF Policy:**

1. Search "Web Application Firewall policies"
2. Click on "my-waf-policy"
3. Left menu → "Policy settings"
4. Mode → Select "Prevention"
5. Click "Save"
6. Left menu → "Managed rules"
7. Ensure OWASP rules are enabled
8. Click "Save"

**Get Application Gateway IP:**

1. Go to Application Gateway → Overview
2. Copy "Frontend public IP address"
3. Save in Notepad

**Expected Result:**
✅ Application Gateway created
✅ Tier: WAF V2
✅ WAF Mode: Prevention
✅ OWASP Rules: Enabled
✅ Backend: revanth-fitness App Service
✅ Public IP: Saved

---

## PHASE 6: CDN & Global Load Balancing

---

### Task 18, 19, 20 & 21: Create Azure Front Door + CDN

**Navigation:**
Azure Portal → Search "Front Door and CDN profiles" →

Create → Azure Front Door → Custom Create

**Configuration:**

| Tab    | Field          | Value              |
| ------ | -------------- | ------------------ |
| Basics | Subscription   | Your subscription  |
| Basics | Resource Group | `my-app-rg`        |
| Basics | Name           | `my-app-frontdoor` |
| Basics | Tier           | `Premium`          |

**Endpoint:**

| Field         | Value             |
| ------------- | ----------------- |
| Endpoint Name | `my-app-endpoint` |
| Status        | `Enabled`         |

**Route:**

| Field               | Value                    |
| ------------------- | ------------------------ |
| Name                | `my-app-route`           |
| Patterns            | `/*`                     |
| Protocols           | `HTTP and HTTPS`         |
| Redirect            | `HTTPS redirect enabled` |
| Forwarding Protocol | `HTTPS only`             |
| Caching             | `Enabled`                |
| Compression         | `Enabled`                |

**Origin Group:**

| Field                 | Value                |
| --------------------- | -------------------- |
| Name                  | `appgw-origin-group` |
| Health Probe Protocol | `HTTP`               |
| Health Probe Path     | `/`                  |
| Health Probe Interval | `30 seconds`         |

**Origin:**

| Field       | Value                      |
| ----------- | -------------------------- |
| Name        | `appgw-origin`             |
| Origin Type | `Custom`                   |
| Host Name   | Application Gateway DNS/IP |
| HTTP Port   | `80`                       |
| HTTPS Port  | `443`                      |
| Priority    | `1`                        |
| Weight      | `1000`                     |

**WAF Policy:**

| Field       | Value              |
| ----------- | ------------------ |
| Policy Name | `my-frontdoor-waf` |
| Mode        | `Prevention`       |

**Steps:**

1. Go to Azure Portal
2. Search "Front Door and CDN profiles"
3. Click "+ Create"
4. Select "Azure Front Door" → "Custom Create"
5. Fill in Basics configuration
6. Add Endpoint
7. Add Route with origin group
8. Add origin pointing to App Gateway
9. Enable caching
10. Add security/WAF policy
11. Click "Review + Create"
12. Click "Create"
13. Wait 5-10 minutes

**Get Front Door URL:**

1. Go to Front Door resource → Overview
2. Copy "Endpoint hostname"
3. Save: `my-app-endpoint-xxxx.azurefd.net`

**Expected Result:**
✅ Front Door created
✅ Tier: Premium
✅ CDN Caching: Enabled
✅ HTTPS Redirect: Enabled
✅ WAF: Prevention mode
✅ Endpoint URL: Saved

---

## PHASE 7: Application Deployment

---

### Task 22 & 23: Setup GitHub Actions + Secrets

**Navigation:**
GitHub Repo → Settings → Secrets and Variables → Actions

**Get Publish Profile:**

1. Go to App Service → staging slot → Overview
2. Click "Download publish profile"
3. Open file with Notepad
4. Select All (Ctrl+A) → Copy (Ctrl+C)

**Add GitHub Secret:**

1. Go to GitHub repo
2. Click "Settings" tab
3. Left menu → "Secrets and variables" → "Actions"
4. Click "New repository secret"

| Field | Value                          |
| ----- | ------------------------------ |
| Name  | `AZURE_WEBAPP_PUBLISH_PROFILE` |
| Value | Paste publish profile content  |

5. Click "Add secret"

**Create Workflow File:**

1. In GitHub repo
2. Go to `.github/workflows/`
3. Create file: `deploy.yml`
4. Add following content:

```yaml
name: Deploy Fitness Tracker to Azure

on:
  push:
    branches:
      - master
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install --production

      - name: Deploy to Azure Staging Slot
        uses: azure/webapps-deploy@v2
        with:
          app-name: 'revanth-fitness'
          slot-name: 'staging'
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: .
```

Commit changes

**Expected Result:**

```text
✅ Publish profile secret added to GitHub
✅ Workflow file created
✅ Deployment triggers on push to master
```

### Task 24 & 25: Deploy and Test Staging

**Deploy:**

1. Go to GitHub repo → Actions tab
2. Click "Deploy Fitness Tracker to Azure"
3. Click "Run workflow" → "Run workflow"
4. Wait for workflow to complete

**Verify Deployment:**

1. Go to App Service → staging slot
2. Left menu → "Log stream"

Verify you see:

```text
====================================
🚀 Fitness Tracker Server Started
🌐 URL : http://0.0.0.0:8080
📊 Environment : production
====================================
✅ Database connected successfully
📦 Host : xxx.mongo.cosmos.azure.com
🗄️ Database : fitness-tracker
```

**Test Staging URL:**

```text
https://revanth-fitness-staging.azurewebsites.net
```

**Test Checklist:**

```text
□ Homepage loads?
□ Can register new user?
□ Can login?
□ Can add fitness data?
□ Data saves to Cosmos DB?
□ No console errors?
```

**Expected Result:**

```text
✅ App deployed to staging
✅ Database connected
✅ All tests passing
```

### Task 26 & 27: Blue-Green Swap to Production

**Navigation:**

```text
App Service → Deployment Slots → Swap
```

**Steps:**

1. Go to App Service "revanth-fitness"
2. Left menu → "Deployment slots"
3. Click "Swap" (top bar)
4. Source: staging
5. Target: production
6. Review changes
7. Click "Swap"
8. Wait 1-2 minutes

**Test Production:**

```text
https://revanth-fitness.azurewebsites.net
```

**Expected Result:**

```text
✅ Staging swapped to Production
✅ Zero downtime during swap
✅ Production app is live
```

---

## PHASE 8: Verification

### Task 28, 29 & 30: Final Verification

**Test Full Architecture:**

| URL              | Expected Result              |
| ---------------- | ---------------------------- |
| Front Door URL   | App loads via CDN            |
| App Gateway IP   | App loads via WAF            |
| Production URL   | App loads directly           |
| Staging URL      | Staging app loads            |
| /health endpoint | Returns {"status":"healthy"} |

**Verify Cosmos DB:**

1. Go to Cosmos DB → Data Explorer
2. Open "fitness-tracker" database
3. Check if data appears after testing app

**Final Architecture Verification:**

```text
✅ Front Door URL working
✅ CDN caching working
✅ WAF protecting requests
✅ App Gateway routing correctly
✅ App Service running
✅ Blue-Green slots ready
✅ Cosmos DB connected
✅ Data persisting correctly
```

### 🔄 Future Blue-Green Deployment Process

```text
1. Push new code to master branch
        ↓
2. GitHub Actions auto-deploys to staging
        ↓
3. Test on staging URL
        ↓
4. Go to Deployment Slots → Swap
        ↓
5. Production updated with zero downtime!
        ↓
6. If issues → Swap again for instant rollback!
```

### 🏆 Complete Architecture Summary

```text
👤 User
  ↓
🌐 Azure Front Door (my-app-endpoint-xxxx.azurefd.net)
  - Global Load Balancing
  - CDN Caching
  - SSL/HTTPS
  - WAF Protection
  ↓
🛡️ Application Gateway (my-app-gateway)
  - WAF V2
  - OWASP Rules
  - Layer 7 Load Balancing
  ↓
📱 App Service (revanth-fitness)
  - Node.js 20 LTS
  - Production Slot 🔵 (Live)
  - Staging Slot 🟢 (Testing)
  ↓
🗄️ Cosmos DB (my-mongo-cosmos-12345)
  - MongoDB 7.0
  - Serverless
  - fitness-tracker database
```

### 💰 Cost Summary

| Resource                   | Approximate Monthly Cost |
| -------------------------- | ------------------------ |
| App Service Standard S1    | ~$70/month               |
| Application Gateway WAF V2 | ~$250-350/month          |
| Azure Front Door Premium   | ~$330/month              |
| Cosmos DB Serverless       | ~$0-25/month             |
| Total                      | ~$650-775/month          |

💡 Use $200 free credits for testing!
Remember to delete resources when done!

---

### 🗑️ Cleanup (When Done)

```text
Azure Portal → Resource Groups → my-app-rg →
Delete Resource Group → Type "my-app-rg" → Delete

⚠️ This deletes ALL resources at once!
```
