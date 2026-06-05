# 🔐 SSO, OAuth & Cross-Subscription RBAC — Azure Studies

> **Study Goals:** Understand Single Sign-On, OAuth protocol differences, and Cross-Subscription RBAC in Azure
>
> **Format:** WHAT, WHERE, HOW, WHY, REAL USE CASES

---

# 📌 Table of Contents

1. [What is SSO (Single Sign-On)](#1-what-is-sso-single-sign-on)
2. [Difference Between SSO and OAuth](#2-difference-between-sso-and-oauth)
3. [What is Cross-Subscription RBAC](#3-what-is-cross-subscription-rbac)

---

# 1. What is SSO (Single Sign-On)

## 🔷 WHAT

**Single Sign-On (SSO)** is an authentication mechanism that allows a user to **log in once** and gain access to **multiple applications and systems** without being asked to log in again for each one.

Think of it like this:

> You show your ID badge at the office entrance once.
>
> After that, you can walk into any room, use the printer,
>
> access the cafeteria, and enter the server room,
>
> all without showing your badge again.

---

## 🔷 The Problem SSO Solves

```text
WITHOUT SSO (The Old Way):
━━━━━━━━━━━━━━━━━━━━━━━━━━

User needs to access 5 apps:

App 1: Microsoft Teams    → Login with username + password
App 2: Salesforce         → Login with username + password
App 3: GitHub             → Login with username + password
App 4: Azure Portal       → Login with username + password
App 5: Jira               → Login with username + password

Problems:
→ 5 different passwords to remember
→ 5 different login screens
→ Password fatigue → users reuse weak passwords
→ IT team manages 5 separate identity stores
→ Security risk increases with more credentials


WITH SSO (Modern Way):
━━━━━━━━━━━━━━━━━━━━━━

User logs in ONCE to Entra ID (Identity Provider)
        │
        ▼
Gets a TOKEN
        │
        ├──► Microsoft Teams    ✅ Auto-logged in
        ├──► Salesforce         ✅ Auto-logged in
        ├──► GitHub             ✅ Auto-logged in
        ├──► Azure Portal       ✅ Auto-logged in
        └──► Jira               ✅ Auto-logged in

One login. All apps. No repeated prompts.
```

## 🔷 HOW SSO Works — Step by Step

```text
STEP 1: User Tries to Access an App
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User opens Salesforce in browser.

Salesforce checks:
"Does this user have a valid session?"

Answer: NO

→ Redirect to Identity Provider (Entra ID)


STEP 2: User Authenticates to Identity Provider
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User is redirected to Entra ID login page.

User enters:
john@company.com + Password + MFA

Entra ID verifies the credentials.


STEP 3: Identity Provider Issues a Token
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Entra ID creates a signed TOKEN containing:

→ Who the user is (identity claims)
→ What they are allowed to do
→ Token expiry time
→ Issuer (Entra ID)

Token format: JWT (JSON Web Token)


STEP 4: Token Sent to the Application
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Token is sent back to Salesforce.

Salesforce validates the token signature.

Salesforce trusts Entra ID (pre-configured trust).

User is logged in ✅


STEP 5: User Opens Another App
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User now opens GitHub.

GitHub checks:
"Does this user have a valid session?"

Entra ID already has an active session.

GitHub gets the token automatically.

User is logged in WITHOUT entering credentials again ✅
```

## 🔷 SSO Architecture Diagram

```text
                    ┌─────────────────────────┐
                    │   IDENTITY PROVIDER      │
                    │   Microsoft Entra ID     │
                    │                         │
                    │  Stores:                │
                    │  → User identities      │
                    │  → Authentication state │
                    │  → Session tokens       │
                    └─────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼

    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ Salesforce   │  │ GitHub       │  │ Azure Portal │
    │              │  │              │  │              │
    │ Trusts       │  │ Trusts       │  │ Trusts       │
    │ Entra ID     │  │ Entra ID     │  │ Entra ID     │
    │              │  │              │  │              │
    │ Accepts      │  │ Accepts      │  │ Accepts      │
    │ JWT Token    │  │ JWT Token    │  │ JWT Token    │
    └──────────────┘  └──────────────┘  └──────────────┘

USER
 │
 │ Login ONCE to Entra ID
 ▼

Gets SSO Token

 │
 ├──► Salesforce ✅
 ├──► GitHub     ✅
 └──► Azure      ✅
```

## 🔷 SSO Token (JWT) Structure

```text
A JWT Token has 3 parts separated by dots:

xxxxx.yyyyy.zzzzz
  │      │      │
  │      │      └── Signature (verifies token is not tampered)
  │      └───────── Payload (claims — who you are, what you can do)
  └──────────────── Header (algorithm used)


PAYLOAD EXAMPLE (decoded):

{
  "sub":   "john@company.com",
  "name":  "John Smith",
  "roles": ["reader", "contributor"],
  "iss":   "https://login.microsoftonline.com/",
  "aud":   "salesforce.com",
  "exp":   1735689600,
  "iat":   1735686000
}
```

## 🔷 Types of SSO Protocols

| Protocol | Description | Used By |
|----------|-------------|----------|
| SAML 2.0 | XML-based federation protocol | Enterprise apps, legacy SaaS |
| OIDC (OpenID Connect) | Identity layer on top of OAuth 2.0 | Modern web/mobile apps |
| WS-Federation | Microsoft older federation standard | Older Microsoft apps |
| Kerberos | Ticket-based SSO inside domain | Windows domain environments |

## 🔷 SSO in Azure — How It Is Set Up

```text
Azure Portal
   → Microsoft Entra ID
      → Enterprise Applications
         → Select App (e.g., Salesforce)
            → Single Sign-On
               → Choose Protocol (SAML or OIDC)
                  → Configure:
                     → Entity ID
                     → Reply URL (ACS URL)
                     → Signing Certificate
                     → User Attribute Mappings
```

## 🔷 WHERE

```text
SSO is used:

→ Enterprise SaaS applications (Salesforce, ServiceNow, Workday)
→ Microsoft 365 (Teams, SharePoint, Outlook)
→ Azure Portal and Azure services
→ Internal custom applications registered in Entra ID
→ Partner applications (B2B federation)
→ Customer-facing apps (B2C with social login)
```

## 🔷 WHY SSO

| Benefit | Explanation |
|----------|-------------|
| User Experience | Log in once, access everything |
| Security | Fewer passwords = fewer attack surfaces |
| Centralized Control | Revoke access from one place |
| MFA in One Place | Enforce MFA centrally |
| Reduced IT Overhead | Fewer password reset requests |
| Compliance | Centralized audit logs |

## 🔷 REAL USE CASES

| Scenario | How SSO Helps |
|----------|---------------|
| Employee joins company | IT adds user to Entra ID → SSO grants access to all apps |
| Employee leaves company | Disable Entra ID account → Access revoked everywhere |
| Developer opens GitHub, Azure, Jira | SSO authenticates all tabs silently |
| Company acquisition | B2B federation provides shared access |
| User forgets Salesforce password | Salesforce uses Entra ID identity |

---

# 2. Difference Between SSO and OAuth

## 🔷 WHAT

This is one of the most commonly confused topics in identity and security.

```text
SSO   → WHO ARE YOU?
         Authentication

OAuth → WHAT CAN YOU DO?
         Authorization
```

They are related but solve different problems.

## 🔷 Simple Analogy

### SSO (Authentication)

```text
Think of SSO like your EMPLOYEE ID BADGE.

You swipe once at the building entrance.

The system knows WHO YOU ARE.

You don't swipe again for every door.
```

### OAuth (Authorization)

```text
Think of OAuth like ROOM ACCESS PERMISSIONS on your badge.

Your badge may:

→ Open the office floor ✅
→ Open the server room ✅
→ NOT open the CEO's office ❌
→ NOT open the finance vault ❌

OAuth defines WHAT YOUR BADGE ALLOWS YOU TO DO,
not just who you are.
```

---

## 🔷 SSO vs OAuth Comparison Table

| Feature | SSO | OAuth |
|----------|----------|----------|
| Purpose | Authentication | Authorization |
| Answers Question | "Who are you?" | "What can you access?" |
| User Login | Yes | Not necessarily |
| Issues Identity | Yes | No |
| Issues Access Token | Sometimes | Yes |
| Used With | SAML, OIDC, Kerberos | OAuth 2.0 |
| Example | Login once to many apps | Allow app to access your data |

---

## 🔷 How OAuth Works - Step by Step

### Example Scenario

```text
You want Canva to access your Google Drive files.

Instead of giving Canva your Google password,
Google issues a limited access token.
```

### Step 1: User Clicks "Login with Google"

```text
USER
 │
 ▼

Canva

Click:
"Login with Google"

 │
 ▼

Redirected to Google
```

### Step 2: Google Authenticates User

```text
Google asks:

Username
Password
MFA

User successfully authenticates.
```

### Step 3: Google Asks for Consent

```text
Canva requests:

✓ View files
✓ Create files

Google asks:

"Allow Canva to access your Google Drive?"

User clicks:

ALLOW
```

### Step 4: OAuth Token Issued

```text
Google issues:

ACCESS TOKEN

eyJhbGciOi...
```

### Step 5: Canva Uses Token

```text
Canva
   │
   ▼

Calls Google API

Authorization:
Bearer eyJhbGciOi...
```

```text
Google validates token

Token valid?
     │
     ├── YES → Return data
     └── NO  → Deny access
```

---

## 🔷 OAuth Architecture

```text
               ┌────────────────────┐
               │ Resource Owner     │
               │      USER          │
               └─────────┬──────────┘
                         │
                         ▼

               ┌────────────────────┐
               │ Authorization      │
               │ Server             │
               │ (Google / Entra)   │
               └─────────┬──────────┘
                         │
                  Issues Token
                         │
                         ▼

               ┌────────────────────┐
               │ Client App         │
               │ (Canva)            │
               └─────────┬──────────┘
                         │
                 Uses Token
                         │
                         ▼

               ┌────────────────────┐
               │ Resource Server    │
               │ (Google Drive API) │
               └────────────────────┘
```

---

## 🔷 OAuth Tokens

### Access Token

```text
Short-lived token

Used to call APIs

Example:

Authorization:
Bearer eyJhbGciOi...
```

### Refresh Token

```text
Long-lived token

Used to obtain a new access token

Without asking user to log in again.
```

### ID Token

```text
Provided by OpenID Connect (OIDC)

Contains user identity information:

Name
Email
User ID
```

---

## 🔷 OAuth Scopes

```text
OAuth does NOT grant unlimited access.

Permissions are granted using scopes.
```

Examples:

```text
User.Read

Read user's profile
```

```text
Mail.Read

Read mailbox
```

```text
Files.Read

Read files
```

```text
Files.ReadWrite

Read and modify files
```

---

## 🔷 OAuth in Microsoft Entra ID

```text
Azure Portal
   → Microsoft Entra ID
      → App Registrations
         → Register Application
            → API Permissions
               → Add Scopes
```

Example:

```text
Application:
MyWebApp

Requests:

User.Read
Mail.Read

Entra ID issues token
with those permissions.
```

---

## 🔷 WHERE

```text
OAuth is used:

→ Microsoft Graph API
→ Google APIs
→ GitHub APIs
→ Salesforce APIs
→ Mobile applications
→ Web applications
→ Microservices
→ Third-party integrations
```

---

## 🔷 WHY OAuth

| Benefit | Explanation |
|----------|-------------|
| No Password Sharing | Apps never see your password |
| Granular Access | Only specific permissions granted |
| Revocable | Tokens can be revoked |
| Safer Integrations | Third-party apps stay isolated |
| Industry Standard | Supported everywhere |

---

## 🔷 REAL USE CASES

| Scenario | OAuth Usage |
|----------|-------------|
| Teams reads user profile | Microsoft Graph API + OAuth |
| Canva accesses Google Drive | OAuth Authorization |
| GitHub Actions accesses Azure | OAuth Service Principal |
| Mobile App accesses backend API | OAuth Access Token |
| Salesforce accesses Outlook | OAuth Consent + Token |

---

# 3. What is Cross-Subscription RBAC

## 🔷 WHAT

Cross-Subscription RBAC allows a user, group, service principal, or managed identity to access resources across multiple Azure subscriptions using Azure Role-Based Access Control (RBAC).

Without Cross-Subscription RBAC:

```text
User has access to:

Subscription A

Only

Cannot access Subscription B
```

With Cross-Subscription RBAC:

```text
Same user

Can access:

Subscription A
Subscription B
Subscription C

Based on assigned roles.
```

---

## 🔷 Why It Exists

Large organizations often have multiple subscriptions:

```text
Production Subscription

Development Subscription

Testing Subscription

Security Subscription

Networking Subscription
```

A single administrator may need access across all of them.

---

## 🔷 Example Organization

```text
Tenant
│
├── Subscription A
│      ├── VM
│      ├── Storage
│      └── SQL
│
├── Subscription B
│      ├── AKS
│      ├── Key Vault
│      └── App Service
│
└── Subscription C
       ├── Firewall
       ├── Bastion
       └── VNET
```

User:

```text
john@company.com
```

Needs access to all subscriptions.

Cross-Subscription RBAC makes this possible.

---

## 🔷 HOW RBAC Works

### Step 1: User Authenticates

```text
User logs into Azure Portal

Authenticated by Entra ID
```

### Step 2: Azure Checks Role Assignments

```text
Azure evaluates:

Who is the user?

What roles do they have?

At what scope?
```

### Step 3: Authorization Decision

```text
Role Found?
     │
     ├── YES → Access Granted
     └── NO  → Access Denied
```

---

## 🔷 RBAC Scope Hierarchy

```text
Management Group
       │
       ▼

Subscription
       │
       ▼

Resource Group
       │
       ▼

Resource
```

Roles assigned higher in the hierarchy inherit downward.

Example:

```text
Reader

Assigned at Subscription

↓

Can read:

All Resource Groups
All Resources
```

---

## 🔷 Cross-Subscription Example

### Subscription A

```text
Role:
Contributor

Assigned to:

john@company.com
```

### Subscription B

```text
Role:
Reader

Assigned to:

john@company.com
```

Result:

```text
Subscription A

Can:
✓ Create resources
✓ Modify resources
✓ Delete resources

Subscription B

Can:
✓ View resources

Cannot:
✗ Create
✗ Modify
✗ Delete
```

---

## 🔷 RBAC Scope Inheritance

One of the most important concepts in Azure RBAC is inheritance.

```text
Management Group
       │
       ▼

Subscription
       │
       ▼

Resource Group
       │
       ▼

Resource
```

When a role is assigned at a higher level, it automatically applies to all child resources below it.

### Example

```text
Role Assignment:

Owner

Assigned At:

Management Group
```

Result:

```text
User automatically becomes:

Owner of:
✓ Subscription A
✓ Subscription B
✓ Subscription C

And all Resource Groups
And all Resources inside them
```

### Another Example

```text
Role Assignment:

Reader

Assigned At:

Resource Group
```

Result:

```text
Can read:

✓ All resources inside that Resource Group

Cannot read:

✗ Resources in other Resource Groups
```

---

## 🔷 Management Groups

### WHAT

Management Groups are containers that sit above subscriptions.

They help organizations manage multiple subscriptions using a single RBAC assignment.

### Structure

```text
Tenant Root Group
        │
        ▼

Production Management Group
        │
        ├── Subscription A
        ├── Subscription B
        └── Subscription C

Development Management Group
        │
        ├── Subscription D
        └── Subscription E
```

### Example

```text
Assign:

Security Team

Role:
Reader

At:

Production Management Group
```

Result:

```text
Security Team can read:

Subscription A
Subscription B
Subscription C

Automatically
```

No need to assign permissions individually.

---

## 🔷 Common Built-In Azure Roles

### Reader

```text
Can:

✓ View resources

Cannot:

✗ Create
✗ Modify
✗ Delete
```

### Contributor

```text
Can:

✓ Create resources
✓ Modify resources
✓ Delete resources

Cannot:

✗ Assign permissions
```

### Owner

```text
Can:

✓ Full resource management
✓ Assign RBAC roles
✓ Delegate permissions
```

### User Access Administrator

```text
Can:

✓ Manage RBAC assignments

Cannot:

✗ Manage resources
```

---

## 🔷 RBAC Evaluation Process

Whenever a user performs an action:

```text
Create VM
Delete Storage Account
Access Key Vault
Read Logs
```

Azure performs authorization checks.

### Process

```text
User Request
      │
      ▼

Azure Resource Manager (ARM)
      │
      ▼

Check Role Assignments
      │
      ▼

Check Scope
      │
      ▼

Check Allowed Actions
      │
      ▼

Grant or Deny
```

---

## 🔷 Service Principals in Cross-Subscription RBAC

### WHAT

A Service Principal is a non-human identity used by applications and automation.

Examples:

```text
Terraform

GitHub Actions

Azure DevOps

CI/CD Pipelines

Automation Scripts
```

### Example

```text
GitHub Actions
```

Needs access to:

```text
Subscription A

Subscription B

Subscription C
```

Assign:

```text
Contributor

to Service Principal
```

at Management Group scope.

Result:

```text
Pipeline can deploy resources
across all subscriptions.
```

---

## 🔷 Managed Identities in Cross-Subscription RBAC

### WHAT

Managed Identity is an Azure-managed identity assigned to Azure resources.

Examples:

```text
Azure VM

App Service

Function App

Logic App

Container App
```

No passwords or secrets are required.

---

### Example

```text
VM in Subscription A
```

Needs access to:

```text
Storage Account

in

Subscription B
```

Assign:

```text
Storage Blob Data Reader
```

to the VM's Managed Identity.

Result:

```text
VM can access Storage Account
without storing credentials.
```

---

## 🔷 Custom Roles

Built-in roles may not always be sufficient.

Organizations can create custom roles.

### Example

```text
Role Name:

VM Operator
```

Permissions:

```text
Can:

✓ Start VM
✓ Stop VM
✓ Restart VM

Cannot:

✗ Delete VM
✗ Create VM
✗ Modify Network
```

Assign this role across multiple subscriptions.

---

## 🔷 Cross-Tenant vs Cross-Subscription

These are often confused.

### Cross-Subscription

```text
Same Entra ID Tenant

Multiple Subscriptions

Subscription A
Subscription B
Subscription C
```

User exists in same tenant.

RBAC grants access across subscriptions.

---

### Cross-Tenant

```text
Tenant A

and

Tenant B
```

Different identity systems.

Requires:

```text
B2B Collaboration

Guest Accounts

Federation
```

Not just RBAC.

---

## 🔷 Real Enterprise Example

### Company Structure

```text
Contoso Corporation
```

Subscriptions:

```text
Production

Development

Testing

Networking

Security
```

Users:

```text
Developers

Operations Team

Security Team

Network Team
```

Assignments:

```text
Developers
→ Contributor
→ Development Subscription

Operations
→ Contributor
→ Production Subscription

Security
→ Reader
→ All Subscriptions

Network Team
→ Network Contributor
→ Networking Subscription
```

Result:

```text
Least Privilege

Centralized Access Control

Subscription Isolation

Governance
```

---

## 🔷 Security Best Practices

### Principle of Least Privilege

```text
Give only the permissions required.

Do NOT assign Owner
unless absolutely necessary.
```

### Use Groups Instead of Users

Bad:

```text
Assign roles directly to:

john@company.com
mary@company.com
alex@company.com
```

Good:

```text
Create Group:

Azure-Developers

Assign role once to group.
```

### Use Management Groups

```text
Assign roles higher in hierarchy
instead of repeating assignments.
```

### Use PIM (Privileged Identity Management)

```text
Provide Just-In-Time access.

User activates role only when needed.
```

### Enable MFA

```text
Protect privileged accounts
with Multi-Factor Authentication.
```

---

## 🔷 WHERE

```text
RBAC is configured in:

Azure Portal
   → Subscription
      → Access Control (IAM)

or

Management Group
   → Access Control (IAM)

or

Resource Group
   → Access Control (IAM)

or

Individual Resource
   → Access Control (IAM)
```

---

## 🔷 WHY Cross-Subscription RBAC

| Reason | Explanation |
|----------|-------------|
| Centralized Administration | Manage access from one identity system |
| Large Enterprises | Support many subscriptions |
| Governance | Apply policies consistently |
| Security | Enforce least privilege |
| Automation | Service Principals access multiple subscriptions |
| Scalability | Permissions inherit automatically |

---

## 🔷 REAL USE CASES

| Scenario | Solution |
|----------|----------|
| Security team needs visibility across all subscriptions | Reader at Management Group |
| Terraform deploys resources everywhere | Contributor to Service Principal |
| VM accesses storage in another subscription | Managed Identity + RBAC |
| Operations team manages production resources | Contributor on Production Subscription |
| Auditor reviews all environments | Reader across subscriptions |

---

# 📚 Final Summary

| Concept | Key Takeaway |
|----------|-------------|
| SSO | Authenticate once, access many applications |
| OAuth | Authorization framework that issues access tokens |
| JWT | Token carrying identity and authorization claims |
| Entra ID | Cloud Identity Provider |
| RBAC | Controls who can do what in Azure |
| Scope | Management Group → Subscription → Resource Group → Resource |
| Inheritance | Permissions flow downward |
| Cross-Subscription RBAC | Access multiple subscriptions from one identity |
| Service Principal | Non-human identity for applications |
| Managed Identity | Azure-managed identity without secrets |
| Management Groups | Organize subscriptions and simplify RBAC |
| Least Privilege | Grant only required permissions |

---

## 📝 Study Tip

Remember these three questions:

```text
SSO:
"Who are you?"

OAuth:
"What are you allowed to access?"

RBAC:
"What actions can you perform on Azure resources?"
```

A simple memory aid:

```text
SSO   → Identity

OAuth → Permission

RBAC  → Azure Authorization
```

---
