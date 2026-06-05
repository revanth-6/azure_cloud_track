# 🔐 Identity & Authentication — Azure Studies

> **Study Goals:** Understand how on-premises identity integrates with Azure Active Directory (Entra ID)
> **Format:** WHAT, WHERE, HOW, WHY, REAL USE CASES

---

# 📌 Table of Contents

1. [On-Premises AD vs Entra ID](#1-on-premises-ad-vs-entra-id)
2. [How Azure AD Connect Authenticates On-Premises Users](#2-how-azure-ad-connect-authenticates-on-premises-users)
3. [Password Hash Synchronization (PHS)](#3-password-hash-synchronization-phs)
4. [Hash Representation](#4-hash-representation)
5. [Pass-Through Authentication (PTA)](#5-pass-through-authentication-pta)

---

# 1. On-Premises AD vs Entra ID

## 🔷 WHAT

### On-Premises Active Directory (AD DS)
**Active Directory Domain Services (AD DS)** is Microsoft's traditional identity management system installed and managed **inside your own datacenter or office infrastructure**.

It controls:
- Who can log into computers
- What resources users can access
- Group policies applied to machines and users

### Microsoft Entra ID (formerly Azure AD)
**Microsoft Entra ID** is Microsoft's **cloud-based identity and access management** service. It is the identity backbone of Azure, Microsoft 365, and thousands of third-party SaaS applications.

---

## 🔷 Architecture Comparison

```text
ON-PREMISES ACTIVE DIRECTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        [ Domain Controller ]
               │
    ┌──────────┼──────────┐
    │          │          │
[User 1]  [User 2]  [Computer 1]
    │
Logs in using:
Username + Password
    │
AD validates against local database
    │
Access granted to on-prem resources
(File Shares, Printers, Internal Apps)


MICROSOFT ENTRA ID (Azure AD)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        [ Entra ID Tenant ]
               │
    ┌──────────┼──────────┐
    │          │          │
[User 1]  [User 2]  [App Registration]
    │
Logs in using:
Username + Password / MFA / OAuth
    │
Entra ID validates
    │
Access granted to:
Azure Resources, Microsoft 365,
SaaS Apps (Salesforce, GitHub, etc.)
```

---

## On-Premises Active Directory vs Microsoft Entra ID

### Key Differences

| Feature | On-Premises AD | Entra ID (Azure AD) |
|----------|----------|----------|
| Location | Your own datacenter | Microsoft Cloud |
| Protocol | Kerberos, NTLM, LDAP | OAuth 2.0, OIDC, SAML |
| Joined Devices | Domain Join | Azure AD Join / Hybrid Join |
| Authentication | Username + Password (Kerberos Ticket) | Token-based (JWT) |
| Group Policy | ✅ Yes (GPO) | ❌ No (uses Intune instead) |
| MFA Support | Limited (requires ADFS) | ✅ Native MFA |
| Internet Access | ❌ Not designed for it | ✅ Built for internet/cloud |
| Managed By | Your IT team | Microsoft (SaaS) |
| Users Access | File shares, internal apps, printers | Azure, Microsoft 365, SaaS apps |
| Single Sign-On | Limited (on-prem only) | ✅ SSO across thousands of apps |

---

## Protocols Explained

### On-Premises AD Protocols

```text
━━━━━━━━━━━━━━━━━━━━━━━━━
Kerberos  → Ticket-based authentication inside domain
NTLM      → Older challenge-response authentication (fallback)
LDAP      → Directory lookup protocol
```

### Entra ID Protocols

```text
━━━━━━━━━━━━━━━━━━
OAuth 2.0 → Authorization framework
OIDC      → Identity layer on top of OAuth
SAML      → Enterprise SSO federation
JWT       → Token format carrying identity claims
```

---

## Where They Are Used

### On-Premises AD

```text
- Corporate offices
- Private datacenters
- Internal networks
- Legacy applications
```

### Entra ID

```text
- Azure Portal
- Microsoft 365 (Teams, SharePoint, Outlook)
- SaaS applications integrated via SAML/OIDC
- Azure VMs
- Azure App Services
- Azure Kubernetes Service (AKS)
```

---

## Why Both Exist

```text
Companies have been running On-Premises AD for 20+ years.

They cannot simply replace it overnight.

They need BOTH to work together:

- On-Premises AD → Manages local machines and legacy applications
- Entra ID       → Manages cloud resources and modern applications

This is called a HYBRID IDENTITY setup.
```

---

## Real Use Cases

| Scenario | Solution |
|-----------|-----------|
| Employee logs into office laptop | On-Premises AD (Kerberos) |
| Employee accesses Microsoft Teams | Entra ID (OAuth/OIDC) |
| Same user accesses both seamlessly | Hybrid Identity via Azure AD Connect |
| Admin applies security policy to all PCs | Group Policy (On-Premises AD) |
| Admin enforces MFA for cloud apps | Entra ID Conditional Access |
| New company migrating to cloud | Sync On-Premises AD to Entra ID using Azure AD Connect |

---

# 2. How Azure AD Connect Authenticates On-Premises Users

## WHAT

Azure AD Connect (now called Microsoft Entra Connect) is a synchronization tool installed on-premises that acts as a bridge between your On-Premises Active Directory and Microsoft Entra ID.

It keeps identities in sync between the two directories so users can use a single identity for both on-premises and cloud resources.

---

## What Azure AD Connect Does

```text
ON-PREMISES AD                    AZURE ENTRA ID
━━━━━━━━━━━━━━                    ━━━━━━━━━━━━━━

Users                             Cloud Users
Groups          ──────────────→   Cloud Groups
Passwords                         Password Hashes
Attributes                        Synced Attributes
(displayName,
 email, phone)
```

---

## HOW Azure AD Connect Works - Step by Step

### Step 1: Installation

```text
━━━━━━━━━━━━━━━━━━━

Install Azure AD Connect on a
Windows Server inside your on-premises network.

Connect it to:
  → Your On-Prem Domain Controller
  → Your Azure Tenant
```

### Step 2: Initial Synchronization

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Azure AD Connect reads all:
  → User accounts
  → Groups
  → Attributes (email, phone, etc.)

from On-Prem AD

It writes them into Entra ID (Azure AD)
```

### Step 3: Ongoing Delta Sync

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━

Every 30 minutes (default):

Azure AD Connect checks for changes:
  → New users added
  → Passwords changed
  → Users deleted
  → Group membership updated

Changes are pushed to Entra ID automatically.
```

---

## Three Authentication Methods

Azure AD Connect supports three ways to authenticate users:

```text
┌─────────────────────────────────────────────────────────┐
│              AZURE AD CONNECT                           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Method 1: Password Hash Sync (PHS)             │   │
│  │  Syncs password hashes to cloud                 │   │
│  │  Authentication happens in CLOUD ☁️             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Method 2: Pass-Through Authentication (PTA)    │   │
│  │  Authentication happens ON-PREMISES 🏢          │   │
│  │  Password never leaves your network             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Method 3: Federation (ADFS)                    │   │
│  │  Third-party authentication server              │   │
│  │  (Active Directory Federation Services)         │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Full Authentication Flow (Overview)

```text
USER SIGNS INTO AZURE / MICROSOFT 365
             │
             ▼
    Entra ID receives login request
             │
             ▼
    ┌────────────────────┐
    │  Which method is   │
    │  configured?       │
    └────────────────────┘
         │          │
         │          │
    ┌────▼───┐  ┌───▼────────────────┐
    │  PHS   │  │  PTA               │
    │  Auth  │  │  Auth              │
    │  in    │  │  in                │
    │  Cloud │  │  On-Premises       │
    └────────┘  └────────────────────┘
```

---

## WHERE

```text
Azure AD Connect is installed:

→ On a Windows Server 2016/2019/2022
→ Inside your on-premises network
→ Must have line of sight to the Domain Controller
→ Must have internet access to reach Entra ID
```

---

## WHY Azure AD Connect

| Problem | Solution |
|----------|----------|
| Users have separate cloud and on-prem accounts | AD Connect syncs them into one identity |
| IT team manages two separate directories | AD Connect automates synchronization |
| Users forget which password to use | Hybrid identity = same password for both |
| Cloud apps cannot see on-prem users | AD Connect replicates users to Entra ID |

---

## REAL USE CASES

| Use Case | How AD Connect Helps |
|-----------|---------------------|
| Company migrating to Microsoft 365 | Syncs all employees to Entra ID automatically |
| Developer logs into Azure Portal with domain credentials | AD Connect synced their account to the cloud |
| HR adds a new employee to on-prem AD | AD Connect automatically creates an Entra ID account |
| Employee changes password on-prem | PHS syncs the new hash to Entra ID within minutes |

---

# 3. Password Hash Synchronization (PHS)

## WHAT

Password Hash Synchronization (PHS) is an authentication method where Azure AD Connect takes a hash of the user's password hash from On-Premises AD and synchronizes it to Entra ID (Azure AD).

When the user tries to log into Azure or Microsoft 365, Entra ID validates the password directly in the cloud without needing to contact the on-premises domain controller.

> ⚠️ Important: The actual password is NEVER sent to the cloud. Only a processed hash is synchronized.

---

## HOW PHS Works - Step by Step

### PHASE 1: PASSWORD HASH SYNC (Happens On-Premises)

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User's Password: "MySecurePass123!"
        │
        ▼

ON-PREMISES AD stores it as:

NTLM Hash (MD4):
a8f5f167f44f4964e6c998dee827110c
        │
        ▼

Azure AD Connect takes this NTLM Hash
        │
        ▼

Applies additional processing:

  1. Salts the hash (adds random data)
  2. Applies PBKDF2 function
  3. Runs HMAC-SHA256

        │
        ▼

Result: A NEW Hash of the Hash
(called the "Cloud Password Hash")
        │
        ▼

Sends ONLY this processed hash to Entra ID
over an encrypted HTTPS connection
```

### PHASE 2: AUTHENTICATION (Happens in Cloud)

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User tries to log into Azure Portal
        │
        ▼

Types:
john@company.com + MySecurePass123!
        │
        ▼

Entra ID receives login request
        │
        ▼

Applies same processing to submitted password
        │
        ▼

Compares result with stored cloud hash
        │
        ▼

    MATCH? ──── YES ──→ Access Granted ✅
                │
               NO ──→ Access Denied ❌
```

---

## PHS Sync Architecture

```text
ON-PREMISES                              AZURE ENTRA ID
━━━━━━━━━━━━━━━━━━━━━                   ━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────┐                 ┌─────────────────────┐
│  Domain Controller  │                 │      Entra ID       │
│                     │                 │                     │
│  User: John         │                 │  User: John         │
│  NTLM Hash:         │                 │  Cloud Hash:        │
│  a8f5f167...        │                 │  x9k2m4p8...        │
└─────────────────────┘                 └─────────────────────┘
          │                                       ▲
          ▼                                       │

┌─────────────────────┐                           │
│  Azure AD Connect   │                           │
│                     │    HTTPS (Encrypted)      │
│  1. Read NTLM Hash  │ ─────────────────────────►│
│  2. Salt + PBKDF2   │   Sends PROCESSED Hash    │
│  3. HMAC-SHA256     │   (not original password) │
│  4. Send to cloud   │                           │
└─────────────────────┘                           │
                                                  │
                               Stored securely in Entra ID
```

---

## Sync Schedule

| Sync Type | Timing |
|------------|---------|
| Initial Full Sync | Happens once on first setup |
| Delta Sync | Every 30 minutes (default) |
| Password Sync | Within 2 minutes of change |

---

## Advantages of PHS

| Advantage | Explanation |
|------------|-------------|
| High Availability | Authentication works even if on-prem is down |
| Simple Setup | No additional infrastructure needed |
| Fast Authentication | Cloud validates directly, no on-prem roundtrip |
| Leaked Credential Detection | Microsoft checks hashes against breach databases |
| Backup Auth Method | Can be backup for PTA or ADFS |

---

## Disadvantages of PHS

| Disadvantage | Explanation |
|--------------|-------------|
| Hash leaves on-prem | Some compliance policies disallow this |
| No real-time policy | Disabled accounts take up to 30 minutes to sync |
| Password control | Password policies enforced in cloud, not on-prem AD |

---

## WHERE

```text
PHS is configured inside:

→ Azure AD Connect Wizard
→ During initial setup or reconfiguration

Hashes stored in:

→ Microsoft Entra ID (Azure AD) tenant
→ Encrypted at rest inside Microsoft's infrastructure
```

---

## WHY PHS

```text
Simplest and most resilient authentication method

Works even when on-premises infrastructure is offline

Microsoft recommends it as the default method for most organizations

Enables Identity Protection features in Entra ID
```

---

## REAL USE CASES

| Scenario | Why PHS |
|-----------|----------|
| Company wants users to log into Microsoft 365 with the same password | PHS syncs hashes so cloud authentication works |
| On-prem network goes down | Users can still authenticate to cloud apps |
| Security team wants leaked credential alerts | PHS enables Microsoft's breach detection |
| Small IT team with no ADFS infrastructure | PHS requires no extra servers |

---

# 4. Hash Representation

## WHAT

A hash is the output of a one-way mathematical function that converts any input (like a password) into a fixed-length string of characters.

### Key Properties

- One-way → You cannot reverse a hash back to the original input
- Deterministic → Same input always produces the same hash
- Fixed Length → Output is always the same size regardless of input
- Avalanche Effect → A tiny change in input creates a completely different hash

---

## HOW Hashing Works

```text
INPUT (Password)          HASH FUNCTION          OUTPUT (Hash)
━━━━━━━━━━━━━━━━          ━━━━━━━━━━━━━          ━━━━━━━━━━━━━

"password"          ──── MD5  ────────────→   5f4dcc3b5aa765d61d8327deb882cf99

"password"          ──── SHA1 ────────────→   5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8

"password"          ──── SHA256 ──────────→   5e884898da28047151d0e56f8dc629277...

"password123"       ──── SHA256 ──────────→   ef92b778bafe771e89245b89ecbc08a44a4e166...

"Password"          ──── SHA256 ──────────→   0b14d501a594442a01c6859541bc1418a6...
```

> NOTE: Changing one character completely changes the hash (Avalanche Effect)

---

## Hash Algorithms Used in Identity

### MD4 / NTLM Hash

```text
━━━━━━━━━━━━━━━

- Used by Windows Active Directory
- Stores Windows user passwords
- MD4 is the algorithm behind NTLM hashes

Example:

Password: "Hello123"

NTLM:
6a9c837c31b83d1c7d0a8d671ca83cfd
```

### MD5

```text
━━━

- Older algorithm
- Produces 128-bit hash
- Considered weak/broken for security today
```

### SHA-1

```text
━━━━━

- 160-bit hash
- Also considered weak now
```

### SHA-256

```text
━━━━━━━

- 256-bit hash
- Widely used today
- Part of SHA-2 family
```

### PBKDF2 (Password-Based Key Derivation Function 2)

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Applies hashing MANY times (iterations)
- Makes brute-force attacks extremely slow
- Used by Azure AD Connect for PHS
```

---

## How Active Directory Stores Passwords

```text
USER CREATES PASSWORD: "MyPass123!"
             │
             ▼

Windows applies MD4 algorithm
             │
             ▼

NTLM Hash:
a8f5f167f44f4964e6c998dee827110c
             │
             ▼

Stored in AD database (NTDS.dit file)
on the Domain Controller
```

The actual password `"MyPass123!"` is NEVER stored.

---

## How PHS Creates the Cloud Hash

```text
NTLM Hash (from AD):

a8f5f167f44f4964e6c998dee827110c
             │
             ▼

Step 1: ADD SALT
━━━━━━━━━━━━━━━

A "salt" is random data added to the hash
to prevent two identical passwords from
having the same output.

Salt:
7f3a9b2c (random)

Salted Input:
a8f5f167... + 7f3a9b2c
             │
             ▼

Step 2: APPLY PBKDF2 (1000 iterations)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Applies SHA256 in a loop 1000 times

Makes cracking computationally expensive
             │
             ▼

Step 3: HMAC-SHA256
━━━━━━━━━━━━━━━━━━━

Adds another layer of keyed hashing
             │
             ▼

FINAL CLOUD HASH:

x9k2m4p8r7n1q5t3...
             │
             ▼

Sent to Entra ID over HTTPS

Stored securely in Microsoft Cloud
```

---

## Why Hashing Is Not Enough Alone - Rainbow Table Attack

### PROBLEM: Rainbow Tables

```text
━━━━━━━━━━━━━━━━━━━━━━━

Attackers precompute hashes for millions of common passwords:

Hash Table:

"password"
→ 5f4dcc3b5aa765d61d8327deb882cf99

"123456"
→ e10adc3949ba59abbe56e057f20f883e

"admin"
→ 21232f297a57a5a743894a0e4a801fc3
```

If an attacker gets the hash, they look it up instantly.

### SOLUTION: SALTING

```text
━━━━━━━━━━━━━━━━━

Add random data (salt) before hashing:

"password" + random_salt_xyz
→ unique hash

"password" + random_salt_abc
→ completely different hash
```

Now two users with the same password have DIFFERENT hashes.

Rainbow tables become useless.

---

## Hash Representation Visual Summary

```text
ORIGINAL PASSWORD

"MySecurePass123!"
        │
        ▼ (MD4/NTLM)

NTLM HASH

a8f5f167f44f4964e6c998dee827110c
        │
        ▼ (Salt + PBKDF2 + HMAC-SHA256)

CLOUD HASH (PHS)

x9k2m4p8r7n1q5t3v6w0y2z4...
        │
        ▼ (Stored in)

ENTRA ID
(Microsoft Cloud)

CANNOT reverse:

x9k2m4... ──── ❌ ────→ "MySecurePass123!"
```

---

## WHERE Hash Representation Is Used

| Location | Hash Used | Purpose |
|----------|----------|----------|
| On-Premises AD | NTLM (MD4) | Stores Windows login passwords |
| Entra ID (PHS) | PBKDF2 + HMAC-SHA256 | Cloud authentication |
| Web Applications | bcrypt / SHA-256 | Storing user passwords in databases |
| File Integrity | SHA-256 / MD5 | Checking if files were tampered |
| Digital Signatures | SHA-256 | Verify document authenticity |

---

## WHY Hashing Matters in Security

```text
- Passwords are never stored in plain text, only hashes

- Even if a database is stolen, attackers only get hashes

- Salting prevents precomputed (rainbow table) attacks

- PBKDF2 / bcrypt make brute force attacks extremely slow

- Enables secure password verification without knowing the actual password
```

---

# 5. Pass-Through Authentication (PTA)

## WHAT

Pass-Through Authentication (PTA) is an Azure AD Connect authentication method where the password validation happens directly on the On-Premises Active Directory, not in the cloud.

When a user tries to log into Azure or Microsoft 365:

- Entra ID receives the login request
- It passes the credentials down to an on-premises agent
- The on-premises AD validates the password
- The result (success/fail) is sent back to the cloud

✅ The actual password never leaves the on-premises network and is never stored in the cloud.

---

## HOW PTA Works - Step by Step

### USER LOGIN ATTEMPT

```text
━━━━━━━━━━━━━━━━━

John types:

john@company.com + MySecurePass123!

into Azure Portal / Microsoft 365
```

### STEP 1: Request Reaches Entra ID

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Entra ID sees PTA is configured.

It does NOT validate the password itself.

It queues an encrypted validation request.
```

### STEP 2: On-Premises PTA Agent Picks Up Request

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The PTA Agent (installed on-premises) maintains
a persistent OUTBOUND connection to Entra ID.

It pulls the encrypted validation request.
```

### STEP 3: Agent Validates Against On-Prem AD

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent calls the Windows SSPI API
to validate the credentials against
the local Domain Controller.

Domain Controller checks:

→ Is the password correct?
→ Is the account locked?
→ Is the account disabled?
→ Is the account expired?
```

### STEP 4: Result Sent Back to Entra ID

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent sends encrypted result back to Entra ID:

→ SUCCESS
→ FAILURE
```

### STEP 5: Entra ID Grants or Denies Access

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Access Granted ✅

or

Access Denied ❌
```

---

## PTA Full Architecture Diagram

```text
                        INTERNET
                        ━━━━━━━━━━━━━━━━━━━━━━━━

USER                    MICROSOFT ENTRA ID
 │                            │
 │  1. Login Request          │
 │ ─────────────────────────► │
 │                            │
 │                    Entra ID queues
 │                    encrypted auth request
 │                            │
 │                            │  ◄─────── Outbound connection
 │                            │           maintained by PTA Agent
 │                        ────┘

                        ON-PREMISES NETWORK
                        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

           ┌─────────────────────┐      ┌──────────────────────┐
           │   PTA AGENT         │      │  DOMAIN CONTROLLER   │
           │   (Windows Server)  │      │                      │
           │                     │      │  Validates:          │
           │  2. Pulls encrypted │      │  ✓ Password correct? │
           │     auth request    │      │  ✓ Account active?   │
           │                     │ ───► │  ✓ Not locked out?   │
           │  3. Calls SSPI API  │      │  ✓ Not expired?      │
           │     for validation  │      │                      │
           │                     │ ◄─── │  Returns: YES / NO   │
           │  4. Encrypts result │      └──────────────────────┘
           │     sends to cloud  │
           └─────────────────────┘
                    │
                    │  Encrypted Result
                    ▼
           Microsoft Entra ID
                    │
        ┌───────────┴───────────┐
        │                       │
   SUCCESS ✅               FAILURE ❌
   Grant Access             Deny Access
```

---

## PTA Agent - Key Details

### WHAT IS THE PTA AGENT?

```text
━━━━━━━━━━━━━━━━━━━━━━

- A lightweight software agent
- Installed on Windows Server on-premises
- Does NOT require inbound firewall ports
- Maintains OUTBOUND connection to Entra ID
- Multiple agents can be installed for high availability
```

### COMMUNICATION

```text
━━━━━━━━━━━━━━

- All communication is OUTBOUND from on-premises
- Uses port 443 (HTTPS) outbound only
- Encrypted end-to-end
- No inbound ports need to be opened on firewall
```

### HIGH AVAILABILITY

```text
━━━━━━━━━━━━━━━━━━

Install multiple PTA Agents on different servers.

If one fails, others continue to handle authentication.

Recommended:

→ At least 2 PTA Agents
→ Install on different servers
→ NOT on the Domain Controller itself
```

---

## What On-Premises AD Validates in PTA

```text
When PTA Agent calls the Domain Controller,
the DC checks ALL of the following:

Validation Check              Result if Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Password Correct?           → Authentication Failed
Account Disabled?           → Account Disabled Error
Account Locked Out?         → Account Locked Error
Account Expired?            → Account Expired Error
Password Expired?           → Password Change Required
Logon Hours Restriction?    → Logon Hours Violation
Smart Card Required?        → Smart Card Required
```

✅ This is a major advantage over PHS. Real-time account state checks happen on the Domain Controller.

With PHS, there can be a sync delay before a disabled account is reflected in the cloud.

---

## PTA vs PHS Comparison

| Feature | PHS | PTA |
|----------|----------|----------|
| Where authentication happens | Cloud (Entra ID) | On-Premises DC |
| Password in cloud | Hash stored in cloud | ❌ Never sent to cloud |
| Works if on-prem is down | ✅ Yes | ❌ No |
| Real-time account checks | ❌ Delayed (sync lag) | ✅ Yes (instant) |
| Complexity | Simple | Moderate |
| Extra infrastructure | None | PTA Agent required |
| Compliance (no cloud hash) | ❌ Hash goes to cloud | ✅ Fully on-prem |
| Locked/Disabled detection | Delayed up to 30 min | ✅ Immediate |
| High Availability | Built-in (cloud) | Needs multiple agents |

---

## PTA Security Model

### SECURITY HIGHLIGHTS

```text
━━━━━━━━━━━━━━━━━━━━━

✅ Password NEVER transmitted to cloud
✅ All communication encrypted (TLS)
✅ Only OUTBOUND connections (no inbound firewall rules)
✅ Credentials validated using Windows SSPI (secure API)
✅ Response is only YES or NO, not the password
✅ Validation request is encrypted with certificate
```

### WHAT TRAVELS OVER THE NETWORK

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cloud → Agent: Encrypted authentication request

Agent → Cloud: Encrypted YES/NO result
```

The password itself NEVER leaves on-premises.

---

## WHERE

```text
PTA Agent Installed On:

→ Windows Server 2012 R2 or later
→ On-premises network (NOT in DMZ)
→ Must reach Domain Controllers on port 389/636
→ Must reach internet on port 443
```

```text
PTA Configured In:

→ Azure AD Connect wizard
→ Can be switched from PHS to PTA
→ Entra ID Portal → Azure AD Connect settings
```

---

## WHY Choose PTA

| Reason | Explanation |
|----------|----------|
| Compliance | Regulations require passwords never leave on-premises |
| Real-time control | Disabling an account immediately blocks cloud access |
| Security policy | Some organizations do not want credential data in cloud |
| Password policies | On-prem password complexity and history enforced |
| Audit requirements | All authentication events logged on-prem Domain Controller |

---

## REAL USE CASES

| Scenario | Why PTA |
|----------|----------|
| Bank with compliance rule requiring no credentials in cloud | PTA keeps all authentication on-premises |
| IT disables a terminated employee's account | PTA blocks cloud access instantly (no sync delay) |
| Healthcare company with HIPAA requirements | PTA keeps sensitive identity data on-premises |
| Company needs on-prem audit logs for all authentication | PTA logs all authentication on Domain Controller |
| Zero tolerance for account compromise | PTA enforces account lockout policies in real time |

---

# Summary Table

| Concept | Key Takeaway |
|----------|-------------|
| On-Prem AD | Traditional identity, Kerberos, LDAP, Group Policy, internal only |
| Entra ID | Cloud identity, OAuth, OIDC, MFA, SSO for cloud and SaaS apps |
| Azure AD Connect | Bridge that syncs identities from on-prem AD to Entra ID |
| PHS | Password hash synced to cloud, authentication in cloud |
| Hash | One-way transformation of password, salted and layered for security |
| PTA | Credentials validated on-premises, nothing stored in cloud |

---

## Decision Guide - Which Method to Choose?

```text
START
  │
  ▼

Do you have compliance requirements
that prevent ANY credential data going to cloud?

  │
  ├── YES ──► Use PTA
  │            (Passwords never leave on-prem)
  │
  └── NO
       │
       ▼

Do you need cloud authentication to work
even if on-premises is down?

       │
       ├── YES ──► Use PHS
       │            (Cloud authentication is independent)
       │
       └── NO
            │
            ▼

Do you need a third-party identity provider
or advanced claims transformation?

            │
            ├── YES ──► Use ADFS (Federation)
            │
            └── NO ──► Use PHS (recommended default)
```

---

## Study Tip

Remember the core difference:

```text
PHS → Hash goes to cloud, cloud validates → Works offline

PTA → Nothing goes to cloud, on-prem validates → Real-time control
```

Microsoft recommends PHS as the default for most organizations due to its simplicity and resilience.

---
