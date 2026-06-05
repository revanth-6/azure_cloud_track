# Azure AD Connect (Microsoft Entra Connect) - Hybrid Identity Lab Setup

## Overview

This documentation covers the end-to-end setup of Microsoft Entra Connect Sync to synchronize On-Premises Active Directory users to Azure Cloud (Microsoft Entra ID).

This is a lab setup where an Azure VM is used to simulate an On-Premises environment.

---

## Architecture

```text
+---------------------------+        +---------------------------+
| Azure VM (Simulated       |        | Microsoft Entra ID        |
| On-Premises)              | Sync   | (Azure Cloud)             |
|                           |------->|                           |
| - Windows Server 2022     |        | - Cloud Users             |
| - Active Directory        |        | - Hybrid Users            |
| - Entra Connect Sync      |        |                           |
+---------------------------+        +---------------------------+
```

---

## Prerequisites

| Item | Details |
|---|---|
| Azure Account | Active Azure Subscription |
| Cloud Admin Account | Global Administrator Role Required |
| Cloud Account Used | `User-8@muralicse1984gmail.onmicrosoft.com` |
| VM Size | Standard_B2s (Minimum) |
| OS | Windows Server 2022 Datacenter: Azure Edition - Desktop Experience |

---

# Phase 1: Create the Windows Server VM in Azure

## Step 1: Log into Azure Portal

1. Open browser and go to `https://portal.azure.com`
2. Login with your Global Administrator account

## Step 2: Navigate to Virtual Machines

1. In the top search bar, type **"Virtual Machines"**
2. Click on **"Virtual Machines"** from the results
3. Click **"+ Create"** > Select **"Azure Virtual Machine"**

## Step 3: Fill in the Basics Tab

### Project Details

| Field | Value |
|---|---|
| Subscription | Select your existing subscription |
| Resource Group | Click "Create New" > Type `OnPrem-Lab-RG` > Click OK |

### Instance Details

| Field | Value |
|---|---|
| Virtual Machine Name | `OnPrem-DC-VM` |
| Region | Choose closest region (e.g., East US) |
| Availability Options | No infrastructure redundancy required |
| Security Type | Standard |
| Image | Windows Server 2022 Datacenter: Azure Edition - Desktop Experience |
| VM Architecture | x64 |
| Size | Standard_B2s |

> ⚠️ Important: Make sure to select "Desktop Experience" version.  
> Without Desktop Experience, you will get a Core (CMD only) version with no GUI.

### Administrator Account

| Field | Value |
|---|---|
| Username | `labadmin` |
| Password | `Lab@12345678` |
| Confirm Password | `Lab@12345678` |

### Inbound Port Rules

| Field | Value |
|---|---|
| Public Inbound Ports | Allow Selected Ports |
| Select Inbound Ports | RDP (3389) |

## Step 4: Disks Tab

| Field | Value |
|---|---|
| OS Disk Type | Standard SSD |
| Everything else | Leave as Default |

## Step 5: Networking Tab

- Leave everything as default
- Ensure Public IP is assigned

## Step 6: Management Tab

- Leave everything as default

## Step 7: Monitoring Tab

| Field | Value |
|---|---|
| Boot Diagnostics | Disable (to save cost) |

## Step 8: Review + Create

1. Click **"Review + Create"**
2. Wait for **"Validation Passed"**
3. Click **"Create"**
4. Wait **3-5 minutes** for deployment

## Step 9: Get the Public IP

1. Click **"Go to Resource"** after deployment
2. Copy the Public IP Address from the overview page

---

# Phase 2: Connect to the VM via RDP

## Step 10: RDP into the VM

1. On your laptop press **Windows Key + R**
2. Type `mstsc` and press **Enter**
3. Enter the Public IP in the Computer field
4. Click **"Connect"**
5. Enter credentials:
   - Username: `labadmin`
   - Password: `Lab@12345678`
6. Click **"Yes"** for the certificate warning

## Common RDP Error and Fix

> Error Code 0x904 - Cannot connect to remote computer

| Check | Solution |
|---|---|
| VM Status | Make sure VM is in "Running" state |
| Public IP | Confirm Public IP is assigned and correct |
| NSG Rule | Add Inbound rule for Port 3389 (RDP) |
| Firewall | Temporarily disable laptop firewall to test |

### How to Add RDP Rule in NSG

1. Go to VM > **"Networking"** in left panel
2. Click **"Add inbound port rule"**
3. Fill in:
   - Destination Port: `3389`
   - Protocol: `TCP`
   - Action: `Allow`
   - Priority: `300`
   - Name: `Allow-RDP`
4. Click **"Add"**

---

# Phase 3: Install Active Directory Domain Services

## Step 11: Open Server Manager

- Server Manager opens automatically after login
- If not, search "Server Manager" in Start Menu

## Step 12: Add Active Directory Role

1. Click **"Manage"** > **"Add Roles and Features"**
2. Click **"Next"**
3. Select **"Role-based or feature-based installation"**
4. Click **"Next"**
5. Server will be auto-selected
6. Click **"Next"**
7. Check **"Active Directory Domain Services"**
8. Click **"Add Features"** on the popup
9. Click **"Next"** through remaining pages
10. Click **"Install"**
11. Wait **2-3 minutes**
12. Click **"Close"**

## Step 13: Promote Server to Domain Controller

1. Click the Yellow Flag icon in Server Manager (top right)
2. Click **"Promote this server to a domain controller"**

Fill in:

| Field | Value |
|---|---|
| Deployment Operation | Add a new forest |
| Root Domain Name | `muralilab.local` |
| Forest Functional Level | Windows Server 2016 |
| Domain Functional Level | Windows Server 2016 |
| DNS Server | ✅ Checked |
| DSRM Password | `Lab@12345678` |

4. Click **"Next"** through remaining pages
5. Click **"Install"** on Prerequisites Check page
6. Server will automatically restart

## Step 14: RDP Back After Restart

1. Wait **2-3 minutes** for VM to restart
2. Open `mstsc` again
3. Enter credentials:
   - Username: `MURALILAB\labadmin`
   - Password: `Lab@12345678`

> ⚠️ Note: Username format changes to `MURALILAB\labadmin` after domain is created.

---

# Phase 4: Create a Test User in Active Directory

## Step 15: Open Active Directory Users and Computers

1. Click Start Menu
2. Search **"Active Directory Users and Computers"**
3. Click to open

## Step 16: Create Test User

1. Expand `muralilab.local`
2. Click **"Users"** folder
3. Right-click **"Users"** > **"New"** > **"User"**

Fill in:

| Field | Value |
|---|---|
| First Name | `Test` |
| Last Name | `User` |
| User Logon Name | `testuser` |

5. Click **"Next"**

Set Password:

| Field | Value |
|---|---|
| Password | `Lab@12345678` |
| User must change password at next logon | ❌ Unchecked |
| Password never expires | ✅ Checked |

7. Click **"Next"**
8. Click **"Finish"**

---

# Phase 5: Download and Install Microsoft Entra Connect

## Step 17: Download Entra Connect

> ⚠️ Important Note: Microsoft no longer provides Entra Connect on the Microsoft Download Center. It is now only available through the Microsoft Entra Admin Center.

1. Inside the VM, open Microsoft Edge
2. Go to `https://entra.microsoft.com`
3. Login with `User-8@muralicse1984gmail.onmicrosoft.com`
4. Navigate to:

```text
Identity
  → Hybrid Management
      → Microsoft Entra Connect
          → Connect Sync
```

5. Click **"Download Microsoft Entra Connect"**
6. Save the installer to the Desktop

## Step 18: Install Microsoft Entra Connect

### Launch the Installer

1. Double-click the downloaded file on Desktop
2. Check **"I agree to the license terms"**
3. Click **"Continue"**
4. Click **"Use Express Settings"**

### Connect to Microsoft Entra (Cloud)

| Field | Value |
|---|---|
| Username | `User-8@muralicse1984gmail.onmicrosoft.com` |
| Password | Your Azure Password |

Click **"Next"**

### Connect to AD DS (On-Premises)

| Field | Value |
|---|---|
| Username | `MURALILAB\labadmin` |
| Password | `Lab@12345678` |

Click **"Add Directory"**
Click **"Next"**

### Microsoft Entra Sign-in Configuration

You will see this warning:

```text
Active Directory UPN Suffix     Microsoft Entra ID Domain

muralilab.local                 Not Added
```

> This is expected and normal for a lab environment.  
> The `.local` domain cannot be verified in Azure.

✅ Check the box:

```text
Continue without matching all UPN suffixes to verified domains
```

Click **"Next"**

### Ready to Configure

✅ Make sure this is checked:

```text
Start the synchronization process when configuration completes
```

Click **"Install"**

Wait **3-5 minutes** for installation to complete.

Click **"Exit"**

---

# Phase 6: Verify the Sync

## Step 19: Check Synced Users in Azure Portal

1. Go to `https://portal.azure.com` on your laptop browser
2. Login with `User-8@muralicse1984gmail.onmicrosoft.com`
3. Search **"Microsoft Entra ID"**
4. Click **"Users"**
5. Click **"All Users"**
6. Look for **"Test User"**
7. Click on **"Test User"**

Verify:

| Field | Expected Value |
|---|---|
| On-premises sync enabled | Yes ✅ |
| Source | Windows Server AD |

---

# Important Notes

## UPN Suffix Behavior

Since the On-Premises domain is `muralilab.local` and cannot be verified in Azure, synced users will appear in Azure with the following UPN format:

```text
testuser@muralicse1984gmail.onmicrosoft.com
```

---

## Cost Management

| Action | How to do it |
|---|---|
| Stop VM when not in use | Go to VM > Click Stop |
| Start VM again | Go to VM > Click Start |
| Delete everything when done | Delete Resource Group `OnPrem-Lab-RG` |

> ⚠️ Always stop the VM when you are not using it to avoid unnecessary charges!

---

# Troubleshooting

## RDP Connection Failed (Error 0x904)

| Cause | Fix |
|---|---|
| VM not running | Start the VM from Azure Portal |
| No Public IP | Assign a Public IP to the VM |
| NSG blocking port 3389 | Add inbound rule to allow RDP |
| Laptop firewall blocking | Temporarily disable Windows Firewall |

## Entra Connect Download Shows PDF

| Cause | Fix |
|---|---|
| Microsoft moved download location | Download from `https://entra.microsoft.com` instead |

## UPN Suffix Warning During Install

| Cause | Fix |
|---|---|
| `.local` domain not verified in Azure | Check "Continue without matching all UPN suffixes" box |

## Users Not Showing in Azure After Sync

| Cause | Fix |
|---|---|
| Sync not completed yet | Wait 10-15 minutes |
| Sync service not running | Restart "Microsoft Azure AD Sync" service on VM |

---

# Summary

```text
✅ Created Windows Server 2022 VM in Azure

✅ Connected via RDP

✅ Installed Active Directory Domain Services

✅ Promoted Server to Domain Controller (muralilab.local)

✅ Created Test User in Active Directory

✅ Downloaded Microsoft Entra Connect from Entra Admin Center

✅ Installed and Configured Entra Connect Sync

✅ Verified On-Premises user synced to Azure Cloud
```

---

# Author

- Lab performed by: User-8@muralicse1984gmail.onmicrosoft.com
- Date: June 2026
- Purpose: Learning Hybrid Identity with Microsoft Entra Connect

---

*This documentation was created as part of a Hybrid Identity learning lab.*

*Not recommended for production use.*
