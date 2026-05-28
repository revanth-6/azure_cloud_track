# 🌐 Networking Fundamentals — Azure Studies

> **Study Goals:** Understand core networking concepts used in cloud and on-premise infrastructure.
> **Format:** WHAT, WHERE, HOW, WHY, REAL USE CASES

---

# 📌 Table of Contents

1. [IP Address Classification](#1-ip-address-classification)
2. [CIDR](#2-cidr-classless-inter-domain-routing)
3. [Subnets — How to Create & Range](#3-subnets--how-to-create--range)
4. [NAT Gateway](#4-nat-gateway)
5. [VPN — How It Works](#5-vpn--how-it-works)
6. [Layer 4 vs Layer 7](#6-layer-4-vs-layer-7)
7. [Segmentation of IP Address](#7-segmentation-of-ip-address)

---

# 1. IP Address Classification

## 🔷 WHAT
An **IP Address (Internet Protocol Address)** is a unique numerical label assigned to every device connected to a network. It is used to identify and locate devices so they can communicate with each other.

There are two versions:
- **IPv4** → 32-bit address → e.g., `192.168.1.1`
- **IPv6** → 128-bit address → e.g., `2001:0db8:85a3::8a2e:0370:7334`

IPv4 addresses are divided into **5 classes (A, B, C, D, E)** based on the range of the first octet.

---

## 🔷 IP Address Classes (IPv4)

| Class | Range (First Octet) | Default Subnet Mask | Network/Host Split | Usage |
|-------|--------------------|--------------------|-------------------|-------|
| A | 1 – 126 | 255.0.0.0 (/8) | 8 bits Network / 24 bits Host | Large organizations, ISPs |
| B | 128 – 191 | 255.255.0.0 (/16) | 16 bits Network / 16 bits Host | Medium organizations |
| C | 192 – 223 | 255.255.255.0 (/24) | 24 bits Network / 8 bits Host | Small networks, homes |
| D | 224 – 239 | N/A | N/A | Multicast groups |
| E | 240 – 255 | N/A | N/A | Reserved / Research |

> ⚠️ `127.x.x.x` is reserved for **loopback** (localhost). It is NOT part of Class A usable range.

---

## 🔷 Private IP Ranges (Not routable on public internet)

| Class | Private Range |
|-------|--------------|
| A | 10.0.0.0 – 10.255.255.255 |
| B | 172.16.0.0 – 172.31.255.255 |
| C | 192.168.0.0 – 192.168.255.255 |

> These are used inside corporate networks, home networks, and cloud VNets (Virtual Networks).

---

## 🔷 WHERE
- **On every device** — computers, phones, servers, VMs, containers
- **In the cloud** — every Azure VM, subnet, and VNet has an IP address
- **On-premise networks** — routers, switches, firewalls use IP classes for planning

---

## 🔷 HOW
When a device joins a network:
1. It is either **manually assigned** a static IP or
2. Gets one **automatically via DHCP** (Dynamic Host Configuration Protocol)
3. The IP is checked against the class table to determine the **network portion** and **host portion**

---

## 🔷 WHY
- Without IP addresses, devices **cannot communicate** over a network
- Classification helps in **routing, subnetting, and network planning**
- Knowing the class helps you understand **how many hosts** you can have on a network

---

## 🔷 REAL USE CASES
| Scenario | Class Used |
|----------|-----------|
| Azure Virtual Network (VNet) default range | Class A → `10.0.0.0/8` |
| Home WiFi Router | Class C → `192.168.1.x` |
| A university network | Class B → `172.16.x.x` |
| Video streaming (multicast) | Class D → `224.x.x.x` |
| ISP backbone network | Class A → large address space |

---

# 2. CIDR (Classless Inter-Domain Routing)

## 🔷 WHAT
**CIDR** is a method for allocating IP addresses and routing that **replaced the old classful system**. Instead of being stuck with fixed class sizes, CIDR lets you define **custom-sized networks** using a **prefix length** (the number after the `/`).

**Format:** `IP Address / Prefix Length`
**Example:** `192.168.1.0/24`

The `/24` means:
- **24 bits** are the **network** portion
- **8 bits** are the **host** portion
- So you can have **2^8 = 256 addresses** (254 usable, 2 reserved)

---

## 🔷 HOW CIDR Works

IP Address: `192.168.1.0`  
In Binary: `11000000.10101000.00000001.00000000`  

Prefix `/24`:

```text
|----- Network (24 bits) -----|-- Host --|
```

---

## CIDR Quick Reference Table

| CIDR | Subnet Mask       | Total IPs  | Usable IPs        |
|------|-------------------|------------|-------------------|
| /8   | 255.0.0.0         | 16,777,216 | 16,777,214        |
| /16  | 255.255.0.0       | 65,536     | 65,534            |
| /24  | 255.255.255.0     | 256        | 254               |
| /25  | 255.255.255.128   | 128        | 126               |
| /26  | 255.255.255.192   | 64         | 62                |
| /27  | 255.255.255.224   | 32         | 30                |
| /28  | 255.255.255.240   | 16         | 14                |
| /29  | 255.255.255.248   | 8          | 6                 |
| /30  | 255.255.255.252   | 4          | 2                 |
| /32  | 255.255.255.255   | 1          | 1 (single host)   |

> **Formula:** Total IPs = 2^(32 - prefix)
> **Usable IPs** = Total - 2 (Network address + Broadcast address)

---

## 🔷 WHERE
- **Azure VNets** — You define CIDR when creating a Virtual Network (e.g., `10.0.0.0/16`)
- **Subnets** — Each subnet inside a VNet has its own CIDR block
- **AWS, GCP, on-prem** — All modern networking uses CIDR
- **Route tables** — CIDR is used to define where traffic should go

---

## 🔷 WHY
- Old classful system **wasted IP addresses** (e.g., a Class A gave you 16 million IPs even if you only needed 500)
- CIDR gives **flexibility** — you use exactly what you need
- Helps in **route summarization** — reduces the size of routing tables

---

## 🔷 REAL USE CASES

| Scenario | CIDR Used | Reason |
|----------|----------|--------|
| Azure VNet address space | `10.0.0.0/16` | 65,534 IPs for entire virtual network |
| Production Subnet | `10.0.1.0/24` | 254 IPs for production servers |
| Database Subnet | `10.0.2.0/28` | Only 14 IPs needed for DB servers |
| Point-to-Site VPN | `172.16.0.0/24` | Small pool for VPN clients |
| Single server whitelist | `203.0.113.5/32` | Allowing exactly one IP in firewall rules |

---

# 3. Subnets — How to Create & Range

## 🔷 WHAT
A **Subnet (Sub-network)** is a **logical division** of an IP network. It breaks a large network into **smaller, manageable pieces**.

Think of it like this:
- **Network** = A city
- **Subnet** = Neighborhoods inside the city
- **IP Address** = A house address inside a neighborhood

---

## 🔷 WHY Subnets?
- **Security** — Isolate sensitive resources (e.g., DB subnet not exposed to internet)
- **Performance** — Reduces broadcast traffic
- **Organization** — Separate environments (web, app, database tiers)
- **Control** — Apply different rules (NSG, Route Tables) per subnet

---

## 🔷 HOW to Create Subnets

### Step 1 — Start with your network CIDR
Example: `10.0.0.0/16` → gives you 65,534 usable IPs

### Step 2 — Decide how many subnets you need
Subnets needed → affects the prefix length

### Step 3 — Divide the Network

Parent Network: `10.0.0.0/16`

- Subnet 1 (Web): `10.0.1.0/24` → 254 usable IPs  
- Subnet 2 (App): `10.0.2.0/24` → 254 usable IPs  
- Subnet 3 (Database): `10.0.3.0/24` → 254 usable IPs  
- Subnet 4 (Gateway): `10.0.4.0/27` → 30 usable IPs  

```text
10.0.0.0/16
├── 10.0.1.0/24   → Web Tier
├── 10.0.2.0/24   → Application Tier
├── 10.0.3.0/24   → Database Tier
└── 10.0.4.0/27   → Gateway Subnet
```

> ⚠️ Azure reserves 5 IPs per subnet:
>
> - `x.x.x.0` → Network address  
> - `x.x.x.1` → Default gateway  
> - `x.x.x.2` → DNS mapping  
> - `x.x.x.3` → DNS mapping  
> - `x.x.x.255` → Broadcast address  

---

## 🔷 Subnet Range Calculation

Given `10.0.1.0/24`:

| Field | Value |
|-------|-------|
| Network Address | 10.0.1.0 |
| First Usable IP | 10.0.1.1 |
| Last Usable IP | 10.0.1.254 |
| Broadcast | 10.0.1.255 |
| Total IPs | 256 |
| Usable IPs | 254 (or 251 in Azure) |

---

## 🔷 Subnetting Example — Splitting /24 into smaller subnets

Parent: `192.168.1.0/24`

| Subnet | Network Address | Range | Broadcast | Usable IPs |
|--------|----------------|-------|-----------|-----------|
| /25 | 192.168.1.0 | .1 – .126 | .127 | 126 |
| /25 | 192.168.1.128 | .129 – .254 | .255 | 126 |

Split further into /26:

| Subnet | Network Address | Range | Broadcast | Usable IPs |
|--------|----------------|-------|-----------|-----------|
| /26 | 192.168.1.0 | .1 – .62 | .63 | 62 |
| /26 | 192.168.1.64 | .65 – .126 | .127 | 62 |
| /26 | 192.168.1.128 | .129 – .190 | .191 | 62 |
| /26 | 192.168.1.192 | .193 – .254 | .255 | 62 |

---

## 🔷 WHERE (In Azure)

In Azure, you create subnets inside a **Virtual Network (VNet)**:
```text
Azure Portal
   → Virtual Networks
      → Your VNet
         → Subnets
            → + Add Subnet
```


Common Azure subnet types:
| Subnet Name | Purpose |
|-------------|---------|
| `AzureFirewallSubnet` | Required for Azure Firewall (must be /26 minimum) |
| `GatewaySubnet` | Required for VPN/ExpressRoute Gateway |
| `AzureBastionSubnet` | Required for Azure Bastion |
| `web-subnet` | Custom — for web servers |
| `db-subnet` | Custom — for database servers |

---

## 🔷 REAL USE CASES

| Use Case | Subnet Design |
|----------|--------------|
| 3-tier web application | Web /24, App /24, DB /26 |
| Multi-environment setup | Prod /24, Dev /24, Test /24 |
| Secure DB isolation | DB subnet with no internet route, NSG denying all inbound |
| Azure Firewall deployment | Dedicated `AzureFirewallSubnet` /26 |
| VPN connectivity | `GatewaySubnet` /27 or larger |

---

# 4. NAT Gateway

## 🔷 WHAT
**NAT (Network Address Translation) Gateway** is a service that allows resources in a **private subnet** (with no public IP) to **initiate outbound connections** to the internet, while **blocking unsolicited inbound connections**.

Think of it like:
> A shared reception desk in an office. Employees (private VMs) can call out to the internet, but strangers cannot call in directly.

---

## 🔷 HOW NAT Works

Private VM: `10.0.1.4`  
Destination: `google.com (142.250.80.46)`

### WITHOUT NAT

```text
VM (10.0.1.4)
      │
      ▼
Internet
      │
      ▼
No Public IP Available
      │
      ▼
Packet Dropped ❌
```

Reason:
The private IP `10.0.1.4` is not routable on the public internet.

---

### WITH NAT Gateway

```text
VM (10.0.1.4)
      │
      ▼
NAT Gateway
(Translates Private IP → Public IP)
      │
      ▼
Public IP: 20.10.5.1
      │
      ▼
google.com (142.250.80.46)
```

Google sees the request coming from the NAT Gateway Public IP (`20.10.5.1`) ✅

---

### Response Flow

```text
Google Response
      │
      ▼
NAT Gateway
(Translates Public IP → Original Private VM)
      │
      ▼
VM (10.0.1.4) ✅
```

---

## 🔷 Key Concept

NAT Gateway enables outbound internet access for private resources without assigning public IPs directly to the VMs.


### NAT Translation Table Example

| Private IP | Private Port | Public IP | Public Port |
|-----------|-------------|-----------|------------|
| 10.0.1.4 | 45231 | 20.10.5.1 | 10001 |
| 10.0.1.5 | 45232 | 20.10.5.1 | 10002 |
| 10.0.1.6 | 45233 | 20.10.5.1 | 10003 |

All VMs share the **same public IP** but use **different ports** to keep connections separate.

---

## 🔷 Types of NAT

| Type | Description |
|------|-------------|
| **Static NAT** | One private IP maps to one public IP permanently |
| **Dynamic NAT** | Private IP maps to any available public IP from a pool |
| **PAT (Port Address Translation)** | Many private IPs share one public IP using different ports (most common, used by Azure NAT Gateway) |

---

## 🔷 WHERE (Azure NAT Gateway)

In Azure:
```text
Azure Portal
   → NAT Gateways
      → Create NAT Gateway
         → Assign to Subnet
```


- Attached to a **subnet**
- Requires a **Public IP or Public IP Prefix**
- Supports up to **16 Public IPs** (64,000 SNAT ports per IP)

---

## 🔷 WHY NAT Gateway?

| Problem | Solution |
|---------|---------|
| Private VMs need internet access for updates | NAT Gateway provides outbound access without exposing VMs |
| SNAT port exhaustion in large deployments | NAT Gateway scales automatically |
| Security — no inbound internet traffic | NAT only allows outbound-initiated connections |
| Multiple VMs sharing one public IP | NAT handles port mapping automatically |

---

## 🔷 REAL USE CASES

| Use Case | How NAT Helps |
|----------|--------------|
| VM in private subnet needs to download OS updates | NAT Gateway routes outbound traffic |
| App server calling external payment API | NAT Gateway allows the outbound API call |
| DB server needs to reach Azure Storage | NAT allows secure outbound without public IP on DB |
| Whitelisting your outbound IP at a partner API | NAT gives a **static, predictable public IP** to whitelist |

---

# 5. VPN — How It Works

## 🔷 WHAT
A **VPN (Virtual Private Network)** creates an **encrypted, private tunnel** over a public network (internet) that allows secure communication between two endpoints.

Types of VPN:
| Type | Description |
|------|-------------|
| **Site-to-Site VPN** | Connects two entire networks (e.g., on-prem datacenter ↔ Azure VNet) |
| **Point-to-Site VPN** | Connects individual client devices to a network |
| **ExpressRoute** | Dedicated private connection (not over internet) — Azure premium option |

---

## 🔷 HOW VPN Works (Step by Step)

```text
CLIENT (Your Laptop)                    SERVER (Azure VNet)
        |                                        |
        |--- 1. Initiate VPN Connection ------->|
        |<-- 2. Exchange Encryption Keys -------|  (Handshake)
        |--- 3. Encrypted Tunnel Established -->|
        |=======================================|
        |            SECURE VPN TUNNEL          |
        |=======================================|
        |--- 4. Send Encrypted Data Packets --->|
        |<-- 5. Receive Encrypted Response -----|
        |=======================================|
```

---

## 🔷 VPN Workflow Explanation

1. Client initiates a VPN connection request to Azure VPN Gateway.  

2. Both sides perform a cryptographic handshake and exchange encryption keys securely.  

3. A secure encrypted tunnel is established between the client and Azure VNet.  

4. All traffic sent through the tunnel becomes encrypted before transmission.  

5. Azure decrypts the packets, processes the request, encrypts the response, and sends it back securely.  

---

## 🔷 Key Concept

VPN creates a secure encrypted tunnel over the public internet, allowing private and secure communication with Azure resources.

### Key Protocols Used in VPN

| Protocol | Description |
|----------|-------------|
| **IKEv2** | Internet Key Exchange v2 — used for key negotiation |
| **IPSec** | Encrypts and authenticates packets |
| **OpenVPN** | Open source, uses SSL/TLS |
| **SSTP** | Secure Socket Tunneling Protocol — Microsoft proprietary |
| **L2TP/IPSec** | Layer 2 tunneling with IPSec encryption |

---

## 🔷 Site-to-Site VPN — Azure Architecture

```text
On-Premise Network         Internet (Encrypted Tunnel)         Azure VNet
[192.168.0.0/16]  ←—————— IPSec / IKEv2 VPN Tunnel ——————→  [10.0.0.0/16]
        |                                                          |
        |                                                          |
[On-Prem VPN Device]                                 [Azure VPN Gateway]
(Cisco / Fortinet / Palo Alto / etc.)                (VpnGw1 / VpnGw2 / etc.)
```

---

## 🔷 Flow Explanation

1. The on-premise network contains internal private resources.  

2. An on-prem VPN device (Cisco, Fortinet, Palo Alto, etc.) initiates a secure IPSec/IKEv2 tunnel.  

3. The encrypted tunnel travels securely over the public internet.  

4. Azure VPN Gateway terminates the VPN tunnel inside Azure.  

5. Both networks can securely communicate privately using internal IP addresses.  

---

## 🔷 Key Concept

A Site-to-Site VPN securely connects an entire on-premise network to an Azure Virtual Network using an encrypted IPSec/IKEv2 tunnel over the internet.


Azure Components needed:
| Component | Purpose |
|-----------|---------|
| **Virtual Network Gateway** | Azure side of the VPN |
| **Local Network Gateway** | Represents your on-prem device in Azure |
| **Connection** | Links the two gateways |
| **GatewaySubnet** | Dedicated subnet for the gateway (min /27) |

---

## 🔷 WHERE
- **Connecting on-prem to Azure** → Site-to-Site VPN
- **Remote workers accessing Azure resources** → Point-to-Site VPN
- **Secure communication between Azure regions** → VNet-to-VNet VPN
- **Hybrid cloud setups** → VPN as primary or backup to ExpressRoute

---

## 🔷 WHY
- **Security** — All data is encrypted, even over public internet
- **Privacy** — Hides network traffic from ISPs and attackers
- **Remote Access** — Employees can securely access corporate resources
- **Hybrid Cloud** — Seamlessly extend on-prem networks into Azure

---

## 🔷 REAL USE CASES

| Use Case | VPN Type |
|----------|---------|
| Company HQ connecting to Azure VNet | Site-to-Site |
| Developer working from home accessing Azure VMs | Point-to-Site |
| Two Azure VNets in different regions communicating | VNet-to-VNet |
| Disaster recovery — on-prem fails, traffic routes to Azure | Site-to-Site with BGP |
| Secure API calls between partner companies | Site-to-Site |

---

# 6. Layer 4 vs Layer 7

## 🔷 WHAT — OSI Model Quick Overview

```text
Layer 7 — Application   → HTTP, HTTPS, DNS, FTP
Layer 6 — Presentation  → SSL/TLS, Encryption
Layer 5 — Session       → Session Management
Layer 4 — Transport     → TCP, UDP (Ports)
Layer 3 — Network       → IP Addresses, Routing
Layer 2 — Data Link     → MAC Addresses
Layer 1 — Physical      → Cables, Hardware
```

---

## 🔷 Important Focus Areas

We mainly focus on:

- **Layer 4 (Transport Layer)**
  - Handles TCP/UDP communication
  - Works with ports
  - Used heavily in load balancers and firewalls

- **Layer 7 (Application Layer)**
  - Understands HTTP/HTTPS traffic
  - Can inspect URLs, headers, cookies, and requests
  - Used in Application Gateways, WAFs, and reverse proxies

---

## 🔷 Key Concept

- Layer 4 devices make decisions using IP addresses and ports.
- Layer 7 devices make intelligent decisions using application-level data like URLs, headers, and HTTP requests.

---

## 🔷 Layer 4 — Transport Layer

### WHAT

- Operates on **IP Address + Port Number**
- Does NOT inspect packet content
- Works with **TCP and UDP protocols**
- Makes decisions using:
  - Source IP
  - Destination IP
  - Source Port
  - Destination Port

---

### HOW

Incoming Packet:

```text
Source IP:     203.0.113.5
Destination IP: 10.0.1.4
Source Port:  55231
Destination Port: 80
```

Layer 4 Decision:

```text
Forward traffic to 10.0.1.4:80 ✅
```

Important:
Layer 4 does NOT understand the HTTP request inside the packet.  
It only checks networking information like IPs and ports.

---

## 🔷 Azure Layer 4 Services

| Service | Description |
|---------|-------------|
| **Azure Load Balancer** | Distributes TCP/UDP traffic using IP + Port |
| **NSG (Network Security Group)** | Allow/Deny traffic using IP, Port, Protocol |
| **Azure Firewall (DNAT Rules)** | Performs NAT translation at Layer 4 |

---

# 🔷 Layer 7 — Application Layer

### WHAT

- Operates on full application request content
- Can inspect:
  - HTTP headers
  - URLs
  - Cookies
  - Hostnames
- Supports intelligent content-aware routing
- Works with:
  - HTTP
  - HTTPS
  - WebSocket
  - gRPC

---

### HOW

Incoming HTTP Request:

```text
GET /api/products HTTP/1.1
Host: shop.example.com
Cookie: user=premium
```

Layer 7 Routing Decisions:

```text
/api/*       → Route to API servers
/images/*    → Route to CDN/Storage
user=premium → Route to Premium server pool
```

---

## 🔷 Azure Layer 7 Services

| Service | Description |
|---------|-------------|
| **Azure Application Gateway** | HTTP/HTTPS load balancer with WAF |
| **Azure Front Door** | Global Layer 7 load balancer + CDN |
| **Azure API Management** | API gateway with routing, throttling, authentication |
| **Azure Firewall (Application Rules)** | FQDN and application-aware filtering |

---

# 🔷 Layer 4 vs Layer 7 Comparison

| Feature | Layer 4 | Layer 7 |
|---------|---------|---------|
| Works On | IP + Port | HTTP content, URLs, Headers |
| Speed | Very Fast | Slightly Slower |
| Packet Inspection | ❌ No | ✅ Yes |
| Routing Decision | IP/Port Based | URL/Header/Cookie Based |
| SSL Termination | ❌ No | ✅ Yes |
| WAF Support | ❌ No | ✅ Yes |
| Protocol Awareness | TCP/UDP | HTTP/HTTPS/WebSocket |
| Azure Example | Azure Load Balancer | Azure Application Gateway |
| Best Use Case | High-throughput TCP apps | Web apps and API routing |

---

## 🔷 Key Concept

- Layer 4 focuses on network-level traffic forwarding.
- Layer 7 understands application-level requests and can make intelligent routing/security decisions.

---

## 🔷 REAL USE CASES

| Scenario | Layer Used | Service |
|----------|-----------|---------|
| Distribute traffic across 3 web VMs equally | Layer 4 | Azure Load Balancer |
| Route `/api/*` to API servers, `/web/*` to web servers | Layer 7 | Application Gateway |
| Block SQL injection attacks on web app | Layer 7 | App Gateway + WAF |
| Load balance a gaming server (UDP) | Layer 4 | Azure Load Balancer |
| Route traffic based on country/region | Layer 7 | Azure Front Door |
| Whitelist specific IPs for SSH access | Layer 4 | NSG |

---

# 7. Segmentation of IP Address

## 🔷 WHAT

**IP Address Segmentation** refers to dividing an IP address into its logical parts to identify the:

- Network Portion
- Host Portion

```text
IP Address = [ Network Portion ] + [ Host Portion ]
```

The subnet mask (or CIDR prefix) determines where the split occurs.

---

# 🔷 HOW — Binary Breakdown

## Example: `192.168.10.5/24`

```text
IP Address:
192 . 168 . 10 . 5

Binary:
11000000 . 10101000 . 00001010 . 00000101
```

Subnet Mask (`/24`):

```text
11111111 . 11111111 . 11111111 . 00000000

|——————— Network (24 bits) ———————|— Host —|
```

### Result

```text
Network Portion → 192.168.10.0
Host Portion    → 0.0.0.5
```

Device number = `5`

---

# 🔷 Parts of an IP Address

| Part | Description | Example |
|------|-------------|---------|
| **Network Address** | Identifies the network | 192.168.10.0 |
| **Host Address** | Identifies the device in the network | 192.168.10.5 |
| **Subnet Mask** | Defines network/host split | 255.255.255.0 |
| **Broadcast Address** | Sends traffic to all hosts in subnet | 192.168.10.255 |
| **Gateway Address** | Router IP (typically first usable IP) | 192.168.10.1 |

---

# 🔷 Segmentation with Different Prefix Lengths

## `10.0.0.0/8`

```text
Network Portion → 10
Host Portion    → 0.0.0 → 255.255.255

Total Hosts ≈ 16 Million
```

---

## `10.10.0.0/16`

```text
Network Portion → 10.10
Host Portion    → 0.0 → 255.255

Usable Hosts = 65,534
```

---

## `10.10.10.0/24`

```text
Network Portion → 10.10.10
Host Portion    → 0 → 255

Usable Hosts = 254
```

---

## `10.10.10.0/28`

```text
Network Portion → 10.10.10.0
Host Portion    → 0 → 15

Block Size = 16
Usable Hosts = 14

Next Subnet Starts At:
10.10.10.16
```

---

# 🔷 How to Find Network & Broadcast Address

## Using AND Operation

### Given

```text
IP Address : 192.168.1.130/26
```

---

### Binary Representation

```text
IP Address:
11000000.10101000.00000001.10000010

Subnet Mask:
11111111.11111111.11111111.11000000
```

---

### AND Operation

```text
11000000.10101000.00000001.10000000
```

Result:

```text
192.168.1.128  ← Network Address
```

---

## Calculate Broadcast Address

```text
Block Size = 2^(32 - 26)
           = 64
```

```text
Broadcast Address
= Network Address + (Block Size - 1)

= 192.168.1.128 + 63
= 192.168.1.191
```

---

## Final Result

| Item | Value |
|------|------|
| Network Address | 192.168.1.128 |
| Broadcast Address | 192.168.1.191 |
| Usable Range Start | 192.168.1.129 |
| Usable Range End | 192.168.1.190 |

---

# 🔷 WHERE

| Area | Usage |
|------|------|
| Routing Tables | Routers use network portions to forward traffic |
| Firewall Rules | CIDR ranges define allowed/blocked segments |
| Azure NSGs | Source/Destination ranges use segmented IPs |
| VNet Design | Subnetting is IP segmentation in practice |

---

# 🔷 WHY

- Improves routing efficiency
- Creates network security boundaries
- Reduces broadcast traffic
- Enables granular firewall and NSG rules
- Supports scalable enterprise network design

---

# 🔷 REAL USE CASES

| Use Case | Segmentation Applied |
|----------|---------------------|
| Azure VNet with multiple subnets | `10.0.0.0/16` split into `/24` networks |
| NSG rule protecting DB subnet | Deny internet access to `10.0.3.0/24` |
| Enterprise VLAN architecture | Each department uses separate subnet |
| Router packet forwarding | Uses destination network portion |
| Zero Trust Security | Micro-segmentation for workload isolation |

---

# 📚 Summary Table

| Concept | Key Takeaway |
|---------|-------------|
| **IP Classification** | Class A/B/C for unicast, D for multicast |
| **CIDR** | Flexible prefix-based addressing |
| **Subnets** | Divide networks into smaller segments |
| **NAT Gateway** | Enables outbound internet for private resources |
| **VPN** | Secure encrypted tunnel over internet |
| **Layer 4 vs Layer 7** | L4 = IP/Port, L7 = Content-aware routing |
| **IP Segmentation** | Splits network and host portions |

---

> 📝 Study Tip:
>
> Practice subnet calculations manually using binary conversions.
>
> Useful Practice Tool:
>
> `https://cidr.xyz`

---

## 🔷 Next Topic Suggestions

- Azure Virtual Networks (VNet)
- Network Security Groups (NSG)
- Route Tables (UDR)
- Azure Load Balancer
- Azure Application Gateway
- Azure Firewall
