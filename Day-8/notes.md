# 🌐 Site-to-Site VPN & Hub-Spoke Architecture — Azure Study Notes

> **Topics Covered:** Site-to-Site VPN, Hub-Spoke Network Architecture
> **Format:** WHAT, WHY, HOW, WHERE, REAL USE CASES

---

# 📌 Table of Contents

1. [Site-to-Site VPN](#1-site-to-site-vpn)
   - [What is Site-to-Site VPN?](#-what)
   - [Why Do We Need It?](#-why)
   - [How Does It Work?](#-how-it-works)
   - [Azure Components Required](#-azure-components-required)
   - [Step-by-Step Setup](#-step-by-step-setup-in-azure)
   - [Real Use Cases](#-real-use-cases)

2. [Hub-Spoke Network Architecture](#2-hub-spoke-network-architecture)
   - [What is Hub-Spoke?](#-what-1)
   - [Why Do We Need It?](#-why-1)
   - [How Does It Work?](#-how-it-works-1)
   - [Components of Hub VNet](#-components-of-hub-vnet)
   - [Traffic Flow](#-traffic-flow)
   - [Real Use Cases](#-real-use-cases-1)

---

# 1. Site-to-Site VPN

## 🔷 WHAT

A **Site-to-Site (S2S) VPN** is a **permanent, encrypted connection** between 
**two entire networks** — typically your **on-premise network** (office/datacenter) 
and your **Azure Virtual Network (VNet)**.

Unlike Point-to-Site (which connects a single device), Site-to-Site connects 
**entire networks together** — so ALL devices on both sides can communicate 
with each other securely.

---

# 🔷 Site-to-Site VPN Architecture

```text
SITE A                                   SITE B
On-Premise Network                       Azure VNet
(Office / Datacenter)                    (Cloud Network)

[Servers]   [PCs]   [Printers]      [VMs]   [DBs]   [Apps]
     |          |         |             |       |       |
[192.168.1.0/24]                    [10.0.0.0/16]
            |                                |
            |                                |
[On-Prem VPN Device] ←—— IPSec Tunnel ——→ [Azure VPN Gateway]
(Cisco / Fortinet / Palo Alto)         (Azure Managed)
                    |
                    |
            Public Internet
               (Encrypted) 🔒
```

---

## 🔷 Simple Analogy

> Imagine two company offices in different cities.
> Each office has its own internal network (like a LAN).
> Without S2S VPN → employees in Office A CANNOT access servers in Office B privately.
> With S2S VPN → a **secure, private tunnel** is built between both offices.
> Now employees in Office A can access servers in Office B as if they were
> sitting in the same building — **permanently, automatically, securely**.

---

## 🔷 WHY

### Problems Without Site-to-Site VPN

| Problem | Impact |
|---------|--------|
| On-prem servers cannot reach Azure VMs privately | Must use public internet — insecure |
| Azure VMs need public IPs to be reachable | Security risk — exposed to internet |
| Sensitive data travels over public internet | Compliance violation (HIPAA, PCI-DSS) |
| Employees cannot access cloud resources securely | Productivity loss |
| Migrating to cloud requires private connectivity | Cannot safely lift-and-shift |

### Benefits With Site-to-Site VPN

| Benefit | Explanation |
|---------|-------------|
| **Secure connectivity** | All traffic is encrypted with IPSec/IKEv2 |
| **Private communication** | On-prem and Azure share same private IP space |
| **Always-on connection** | Permanent tunnel — no need to connect manually |
| **Transparent to users** | Employees just access resources normally |
| **Hybrid cloud enablement** | Use Azure as extension of your datacenter |
| **Compliance** | Data never travels over unencrypted public internet |
| **Cost effective** | No need for expensive dedicated lines (vs ExpressRoute) |

---

## 🔷 HOW It Works

## 🔷 Phase 1 — IKE (Internet Key Exchange) Handshake

```text
On-Prem VPN Device                  Azure VPN Gateway
        |                                      |
        |—— 1. Hello, I want to connect ——→   |
        |←— 2. Here are my credentials ————   |
        |—— 3. Verify + Exchange Keys ——→     |
        |←— 4. Keys Verified ✅ ————————————   |
        |                                      |
        |—— PHASE 1 TUNNEL ESTABLISHED ——|
              (Control Channel — IKEv2)
```

---

## 🔷 What Happens in Phase 1?

Phase 1 creates a secure and trusted control channel between both VPN devices.

### Main Tasks

- Authenticate both sides
- Exchange cryptographic keys
- Negotiate security parameters
- Establish secure management tunnel

### Common Protocols

| Component | Example |
|-----------|---------|
| Key Exchange | Diffie-Hellman |
| Authentication | Pre-Shared Key (PSK) / Certificates |
| Integrity | SHA-256 |
| Encryption | AES-256 |

---

# 🔷 Phase 2 — IPSec Tunnel (Data Channel)

```text
On-Prem VPN Device                  Azure VPN Gateway
        |                                      |
        |—— 5. Negotiate Encryption Algo ——→  |
        |←— 6. Agreed: AES-256, SHA-256 ——   |
        |                                      |
        |—— PHASE 2 TUNNEL ESTABLISHED ——|
              (Data Channel — IPSec ESP)
        |                                      |
        |===== ENCRYPTED DATA FLOWS =====|
```

---

## 🔷 What Happens in Phase 2?

Phase 2 creates the actual encrypted tunnel used for transferring application and network traffic.

### Main Tasks

- Establish IPSec Security Associations (SAs)
- Select encryption algorithms
- Define traffic encryption rules
- Start encrypted packet transfer

---

## 🔷 Common IPSec Components

| Component | Purpose |
|-----------|---------|
| ESP (Encapsulating Security Payload) | Encrypts VPN traffic |
| AES-256 | Data encryption |
| SHA-256 | Integrity verification |
| Security Association (SA) | Defines encryption settings |

---

# 🔷 Complete VPN Tunnel Flow

```text
Phase 1:
IKEv2 Control Channel Established ✅

Phase 2:
IPSec Data Tunnel Established ✅

Result:
Secure Encrypted Communication Between Networks 🔒
```

---

## 🔷 Key Concept

- Phase 1 builds trust and exchanges keys.
- Phase 2 encrypts and transports actual data traffic.

Without Phase 1 → Phase 2 cannot happen.


# 🔷 Full Traffic Flow

```text
Employee PC (192.168.1.10)
        |
        ↓
On-Prem Router
        |
        ↓
On-Prem VPN Device
        |
        ↓  (Packet Encrypted using IPSec)
══════════════════════════════════════════════
 Encrypted Packet Travels Across Internet 🔒
══════════════════════════════════════════════
        |
        ↓
Azure VPN Gateway
        |
        ↓  (Packet Decrypted)
Azure VM (10.0.1.4) Receives Request ✅

Response follows the same path in reverse ✅
```

---

# 🔷 Protocols Used

| Protocol | Layer | Purpose |
|----------|-------|---------|
| **IKEv2** | Layer 7 | Key exchange and authentication |
| **IPSec** | Layer 3 | Packet encryption and integrity |
| **ESP (Encapsulating Security Payload)** | Layer 3 | Encrypts packet payload |
| **AH (Authentication Header)** | Layer 3 | Authenticates packet origin |
| **BGP (Border Gateway Protocol)** | Layer 3 | Dynamic route exchange |

---

# 🔷 Encryption Standards Supported

| Algorithm Type | Supported Options |
|----------------|------------------|
| Encryption | AES-128, AES-256, 3DES |
| Integrity | SHA-1, SHA-256, SHA-384 |
| DH Groups | DH Group 2, 14, 24, ECP256, ECP384 |

---

# 🔷 Azure Components Required

## Azure Side Architecture

```text
┌──────────────────────────────────────────────┐
│                 Azure VNet                  │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ GatewaySubnet (/27 minimum)           │  │
│  │                                        │  │
│  │  ┌──────────────────────────────────┐  │  │
│  │  │ Virtual Network Gateway         │  │  │
│  │  │ (Azure VPN Gateway)             │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ Local Network Gateway                 │  │
│  │ Represents On-Prem Network            │  │
│  │ - Public IP of VPN Device             │  │
│  │ - On-Prem Address Space               │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ Connection Resource                   │  │
│  │ - IPSec Tunnel                        │  │
│  │ - Shared Key (PSK)                    │  │
│  │ - Tunnel Management                   │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

---

## On-Premise Side

```text
┌──────────────────────────────────────────────┐
│          On-Prem VPN Device                 │
│                                              │
│ Examples:                                   │
│ - Cisco ASA                                 │
│ - Fortinet                                  │
│ - Palo Alto                                 │
│ - pfSense                                   │
│ - Windows RRAS                              │
│                                              │
│ Requirements:                               │
│ - Public IP Address                         │
│ - IPSec / IKEv2 Support                     │
│ - Same Shared Key (PSK)                     │
│ - Azure Gateway Public IP Configured        │
└──────────────────────────────────────────────┘
```

---

# 🔷 Component Descriptions

| Component | What It Is | Purpose |
|-----------|------------|---------|
| **Virtual Network Gateway** | Azure-managed VPN endpoint | Azure side of tunnel |
| **GatewaySubnet** | Dedicated subnet | Hosts VPN Gateway |
| **Local Network Gateway** | Represents on-prem network | Stores on-prem IP details |
| **Connection** | Tunnel relationship | Manages IPSec tunnel |
| **Public IP** | Assigned to VPN Gateway | Internet endpoint |
| **Shared Key (PSK)** | Authentication secret | Validates both sides |

---

# 🔷 VPN Gateway SKUs

| SKU | Max Throughput | Max S2S Tunnels | BGP Support |
|-----|----------------|----------------|-------------|
| Basic | 100 Mbps | 10 | ❌ No |
| VpnGw1 | 650 Mbps | 30 | ✅ Yes |
| VpnGw2 | 1 Gbps | 30 | ✅ Yes |
| VpnGw3 | 1.25 Gbps | 30 | ✅ Yes |
| VpnGw4 | 5 Gbps | 100 | ✅ Yes |
| VpnGw5 | 10 Gbps | 100 | ✅ Yes |

> ⚠️ Basic SKU is NOT recommended for production.
>
> Limitations:
> - No BGP
> - No IKEv2
> - No zone redundancy

---

# 🔷 Static Routing vs BGP

| Feature | Static Routing | BGP Dynamic Routing |
|---------|---------------|-------------------|
| Route Management | Manual | Automatic |
| Route Updates | Manual changes required | Auto-updated |
| Complexity | Simple | Advanced |
| Failover | Manual | Automatic |
| Best For | Small deployments | Enterprise-scale |

---

# 🔷 Step-by-Step Setup in Azure

## Step 1 — Create VNet

```text
Address Space:
10.0.0.0/16

GatewaySubnet:
10.0.255.0/27
```

---

## Step 2 — Create Virtual Network Gateway

```text
Type:
VPN

VPN Type:
Route-Based

SKU:
VpnGw1

Public IP:
Required
```

⏳ Provisioning may take 20–45 minutes.

---

## Step 3 — Create Local Network Gateway

```text
On-Prem Public IP:
203.0.113.10

On-Prem Address Space:
192.168.0.0/16
```

---

## Step 4 — Create Connection

```text
Connection Type:
Site-to-Site (IPSec)

Authentication:
Shared Key (PSK)

Example PSK:
MySecureKey123!

IKE Version:
IKEv2
```

---

## Step 5 — Configure On-Prem VPN Device

Configure:

```text
- Azure VPN Gateway Public IP
- Shared Key (same PSK)
- IPSec/IKE parameters
- Azure address space
```

---

## Step 6 — Verify Connection

```text
Azure Portal
   → VPN Connections
      → Status: Connected ✅
```

Test connectivity:

```text
Ping Azure VM using private IP
10.0.1.4 ✅
```

---

# 🔷 Site-to-Site VPN vs Other Connectivity Options

| Feature | Site-to-Site VPN | ExpressRoute | VNet Peering |
|---------|------------------|--------------|--------------|
| Connects | On-Prem ↔ Azure | On-Prem ↔ Azure | Azure VNet ↔ Azure VNet |
| Path | Encrypted Internet Tunnel | Dedicated Private Circuit | Microsoft Backbone |
| Latency | Medium | Very Low | Very Low |
| Bandwidth | Up to 10 Gbps | Up to 100 Gbps | Very High |
| Cost | Low-Medium | High | Low |
| Setup Time | Hours | Weeks / Months | Minutes |
| Encryption | ✅ IPSec | Optional (MACsec) | ❌ Not Needed |
| SLA | 99.9% | 99.95% | 99.99% |
| Best Use Case | Hybrid Cloud / SMB | Enterprise / Compliance | Azure-to-Azure |

---

# 🔷 REAL USE CASES

---

## 🏢 Use Case 1 — Lift & Shift Migration

### Scenario

A company has 50 on-prem servers and wants gradual migration to Azure.

### Solution

```text
On-Prem Servers
       |
Site-to-Site VPN
       |
Azure VMs
```

Benefits:

- Private IP communication
- No migration downtime
- Hybrid coexistence during migration

---

## 🏦 Use Case 2 — Banking & Compliance

### Scenario

Bank keeps core systems on-prem but uses Azure for analytics.

### Solution

```text
Core Banking Systems
       |
Encrypted IPSec Tunnel
       |
Azure Analytics Platform
```

Benefits:

- PCI-DSS compliance
- Encrypted traffic
- Secure hybrid architecture

---

## 🏪 Use Case 3 — Retail Branch Connectivity

### Scenario

20 branch offices need access to centralized Azure inventory system.

### Solution

```text
Branch Offices
      |
Multiple S2S VPN Tunnels
      |
Azure Inventory System
```

Benefits:

- Centralized inventory
- Private connectivity
- Multiple tunnels supported

---

## 🏥 Use Case 4 — Healthcare Hybrid Cloud

### Scenario

Patient records stay on-prem while apps run in Azure.

### Solution

```text
Hospital Network
       |
Encrypted VPN Tunnel
       |
Azure Healthcare Application
```

Benefits:

- HIPAA compliance
- Secure patient data transfer
- No public exposure

---

## 🔄 Use Case 5 — Disaster Recovery

### Scenario

Primary datacenter fails.

### Solution

```text
On-Prem Datacenter
       |
Existing VPN Tunnel
       |
Azure DR Environment
```

Benefits:

- Fast failover
- Business continuity
- Minimal downtime

---

# 2. Hub-Spoke Network Architecture

# 🔷 WHAT is Hub-Spoke?

Hub-Spoke is a centralized Azure network architecture pattern.

```text
Hub VNet
   ↓
Shared Services

Spoke VNets
   ↓
Individual workloads/environments
```

---

# 🔷 Hub-Spoke Architecture Diagram

```text
                ┌─────────────────────┐
                │      HUB VNet       │
                │─────────────────────│
                │ Azure Firewall      │
                │ VPN Gateway         │
                │ DNS Server          │
                │ Bastion Host        │
                └─────────┬───────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │

┌───────┴────────┐ ┌──────┴────────┐ ┌──────┴────────┐
│ Spoke VNet 1   │ │ Spoke VNet 2  │ │ Spoke VNet 3  │
│ Production     │ │ Development   │ │ Testing       │
│ 10.1.0.0/16    │ │ 10.2.0.0/16   │ │ 10.3.0.0/16   │
└────────────────┘ └────────────────┘ └────────────────┘
```

---

# 🔷 Simple Analogy

```text
Hub = International Airport

Spokes = Regional Airports

All traffic flows through the central hub.
```

---

# 🔷 WHY Hub-Spoke?

# Problems WITHOUT Hub-Spoke

```text
Every VNet peers with every other VNet
```

Problems:

- ❌ Too many peerings
- ❌ Expensive gateways/firewalls
- ❌ No centralized security
- ❌ Hard monitoring and auditing
- ❌ Poor scalability

---

# WITH Hub-Spoke

```text
All VNets connect ONLY to Hub
```

Benefits:

- ✅ Centralized security
- ✅ Shared VPN Gateway
- ✅ Easier management
- ✅ Lower cost
- ✅ Better scalability

---

# 🔷 Benefits of Hub-Spoke

| Benefit | Explanation |
|---------|-------------|
| Centralized Security | One firewall for all traffic |
| Cost Savings | Shared VPN Gateway |
| Scalability | Easy to add new spokes |
| Isolation | Separate environments/workloads |
| Compliance | Consistent policies |
| Simplified Management | Shared services centralized |
| Blast Radius Reduction | Compromise isolated to one spoke |

---

# 🔷 HOW Hub-Spoke Works

# Hub VNet Components

```text
Hub VNet (10.0.0.0/16)

├── AzureFirewallSubnet
│     └── Azure Firewall

├── GatewaySubnet
│     └── VPN Gateway

├── AzureBastionSubnet
│     └── Azure Bastion

├── DNS Subnet
│     └── DNS Services

└── Monitoring Subnet
      └── Logging / Monitoring
```

---

# Spoke VNet Example

```text
Spoke VNet - Production

├── Web Subnet
├── App Subnet
└── DB Subnet
```

---

# 🔷 Components of Hub VNet

| Component | Purpose | Required Subnet |
|-----------|---------|----------------|
| Azure Firewall | Traffic inspection | AzureFirewallSubnet |
| VPN Gateway | Hybrid connectivity | GatewaySubnet |
| ExpressRoute Gateway | Private connectivity | GatewaySubnet |
| Azure Bastion | Secure RDP/SSH | AzureBastionSubnet |
| DNS Services | Name resolution | Custom subnet |
| UDR | Traffic steering | Applied to subnets |
| Network Watcher | Diagnostics | Regional service |
| Log Analytics | Central logging | PaaS service |

---

# 🔷 Traffic Flow Examples

# Spoke-to-Internet

```text
Spoke VM
    ↓
Hub Firewall
    ↓
Internet ✅
```

Firewall decides Allow/Deny.

---

# Spoke-to-Spoke Traffic

```text
Spoke-1 VM
     ↓
Hub Firewall
     ↓
Spoke-2 VM ✅
```

Traffic inspected centrally.

---

# On-Prem to Spoke

```text
On-Prem Network
      ↓
VPN Gateway (Hub)
      ↓
Firewall Inspection
      ↓
Spoke VM ✅
```

One VPN Gateway serves all spokes.

---

# 🔷 Gateway Transit (Critical Concept)

# WITHOUT Gateway Transit

```text
Each Spoke Needs:
- Own VPN Gateway
```

Expensive ❌

---

# WITH Gateway Transit

```text
Hub Has ONE VPN Gateway

All spokes share it via peering.
```

Cost-efficient ✅

---

# 🔷 How to Enable Gateway Transit

## Hub Peering Settings

```text
Allow Gateway Transit = TRUE
```

## Spoke Peering Settings

```text
Use Remote Gateway = TRUE
```

---

# 🔷 Route Tables (UDR)

Without UDR:

```text
Traffic may bypass firewall ❌
```

With UDR:

```text
ALL traffic forced through firewall ✅
```

---

# Example UDR

| Destination | Next Hop Type | Next Hop IP |
|-------------|---------------|-------------|
| 0.0.0.0/0 | Virtual Appliance | 10.0.1.4 |
| 10.0.0.0/8 | Virtual Appliance | 10.0.1.4 |

---

# 🔷 Result

```text
ALL Traffic
     ↓
Azure Firewall
     ↓
Allow or Deny Decision
```

Centralized network security enforcement ✅

---

# 🔷 Hub-Spoke with Azure Virtual WAN

For very large enterprise deployments (100+ spokes), Azure provides  
**Azure Virtual WAN** — a fully managed Hub-Spoke networking service.

---

## 🔷 Traditional Hub-Spoke vs Azure Virtual WAN

| Feature | Traditional Hub-Spoke | Azure Virtual WAN |
|---------|----------------------|------------------|
| Hub Management | You manage Hub VNet | Microsoft-managed |
| Spoke Connections | Manual VNet Peering | Automated |
| Routing | Manual UDR Management | Automated Routing |
| Scale | Medium | Massive (1000s of spokes) |
| Any-to-Any Connectivity | Manual Setup | Built-In |
| Cost | Lower | Higher |
| Complexity | Higher Operational Effort | Lower Operational Effort |

---

# 🔷 WHERE Hub-Spoke is Used

Hub-Spoke is commonly used in:

- ✅ Large enterprise organizations
- ✅ Financial institutions
- ✅ Healthcare systems
- ✅ Government environments
- ✅ Hybrid cloud deployments
- ✅ Multi-region Azure environments
- ✅ Managed Service Providers (MSPs)
- ✅ Organizations requiring centralized governance

---

# 🔷 REAL USE CASES

---

# 🏦 Use Case 1 — Large Bank (Multi-Department)

```text
Hub VNet
├── Azure Firewall
├── ExpressRoute Gateway
└── Bastion

Spoke-1 → Retail Banking
Spoke-2 → Investment Banking
Spoke-3 → Risk & Compliance
Spoke-4 → HR Systems
Spoke-5 → IT Operations
```

## Benefits

- Retail Banking isolated from Investment Banking ✅
- Centralized firewall inspection ✅
- One ExpressRoute shared by all spokes ✅
- Central logging and compliance auditing ✅
- Easy onboarding of new departments ✅

---

# 🏥 Use Case 2 — Healthcare System

```text
Hub VNet
├── Azure Firewall
├── VPN Gateway
├── Bastion
└── Private DNS

Spoke-1 → Patient Records
Spoke-2 → Clinical Applications
Spoke-3 → Billing Systems
Spoke-4 → Research Systems
Spoke-5 → Partner Integrations
```

## Benefits

- Patient data fully isolated ✅
- HIPAA compliance logging ✅
- Controlled partner access ✅
- Centralized security policies ✅

---

# 🌍 Use Case 3 — Global Multi-Region Company

```text
East US Region
├── Hub-EastUS
├── Production-East
└── Development-East

West Europe Region
├── Hub-WestEurope
├── Production-Europe
└── Development-Europe

Hub-EastUS ←—— Global VNet Peering ——→ Hub-WestEurope
```

## Benefits

- Regional autonomy ✅
- Cross-region communication ✅
- Disaster recovery support ✅
- Global routing optimization ✅

---

# 🏗️ Use Case 4 — DevOps / Software Company

```text
Hub VNet
├── Azure Firewall
├── Bastion
├── Private DNS
└── VPN Gateway

Spoke-1 → Production
Spoke-2 → Staging
Spoke-3 → Development
Spoke-4 → CI/CD
Spoke-5 → Monitoring
```

## Traffic Rules

```text
CI/CD → Staging      ✅ Allowed
CI/CD → Production  ❌ Blocked
Dev → Production DB ❌ Blocked
SSH Access          ✅ Via Bastion Only
```

---

# 🏪 Use Case 5 — Managed Service Provider (MSP)

```text
MSP Hub VNet
├── Azure Firewall
├── VPN Gateway
├── Bastion
└── Monitoring

Client-A Spoke
Client-B Spoke
Client-C Spoke
Client-D Spoke
```

## Benefits

- Client isolation ✅
- Shared management services ✅
- Simplified onboarding ✅
- Centralized monitoring ✅
- Strong tenant separation ✅

---

# 📚 Summary Table

| Topic | Key Takeaway |
|------|--------------|
| Site-to-Site VPN | Permanent encrypted tunnel between on-prem and Azure |
| S2S Components | VPN Gateway, GatewaySubnet, LNG, Connection, PSK |
| S2S Protocols | IKEv2 + IPSec/ESP |
| ExpressRoute | Dedicated private connectivity |
| Hub-Spoke | Centralized shared-services architecture |
| Gateway Transit | Shared Hub VPN Gateway for all spokes |
| UDR | Forces traffic through firewall |
| Hub Components | Firewall, Gateway, Bastion, DNS, Monitoring |
| Not Transitive | Spoke-to-Spoke requires Hub routing |

---

# 🔷 Key Concepts to Remember

```text
VNet Peering is NOT transitive

Spoke-to-Spoke traffic must pass through:
Hub → Firewall → Routing Controls
```

```text
Gateway Transit allows ALL spokes
to share ONE VPN Gateway
```

```text
UDRs force traffic through the Hub Firewall
for centralized inspection and policy enforcement
```

---

> 📝 Study Tips:
>
> - Draw Hub-Spoke topology manually with CIDR ranges
> - Practice creating:
>   - Hub VNet
>   - Spoke VNets
>   - Peering
>   - Gateway Transit
>   - UDRs
>
> - Understand WHY UDRs are required
> - Remember:
>
> ```text
> Peering is NOT transitive
> ```
>
> This is the foundation of Hub-Spoke traffic flow.
