# Azure Application Gateway with WAF & Path-Based Routing

## Phase 1: Resource Group

### Step 1: Create Resource Group

1. Go to `portal.azure.com`.
2. Search for `Resource Groups` in the top search bar.
3. Click `+ Create`.
4. Fill in the following details:

| Field | Value |
|---|---|
| Subscription | Your subscription |
| Resource Group Name | AppGateway-RG |
| Region | Central India |

5. Click `Review + Create`.
6. Click `Create`.

---

## Phase 2: Virtual Network & Subnets

### Step 2: Create Virtual Network with 2 Subnets

1. Search for `Virtual Networks` in the search bar.
2. Click `+ Create`.

### Basics Tab

Fill in the following details:

| Field | Value |
|---|---|
| Subscription | Your subscription |
| Resource Group | AppGateway-RG |
| Name | AppGateway-VNet |
| Region | Central India |

### IP Addresses Tab

1. Go to the `IP Addresses` tab.
2. Set the IPv4 address space:

| Field | Value |
|---|---|
| IPv4 Address Space | 10.0.0.0/16 |

3. Delete the default subnet if it is already present.

### Add VM Subnet

1. Click `+ Add Subnet`.
2. Add the following subnet details:

| Field | Value |
|---|---|
| Subnet Name | VM-Subnet |
| Subnet Range | 10.0.1.0/24 |

### Add Application Gateway Subnet

1. Click `+ Add Subnet` again.
2. Add the following subnet details:

| Field | Value |
|---|---|
| Subnet Name | AppGateway-Subnet |
| Subnet Range | 10.0.2.0/24 |

> Note: Application Gateway requires a dedicated subnet. No other resources should be placed inside this subnet.

3. Click `Review + Create`.
4. Click `Create`.

---

## Phase 3: Virtual Machines

### Step 3: Create VM 1 - Fitness App

1. Search for `Virtual Machines` in the search bar.
2. Click `+ Create`.
3. Select `Azure Virtual Machine`.

### Basics Tab

Fill in the following details:

| Field | Value |
|---|---|
| Resource Group | AppGateway-RG |
| VM Name | VM-Fitness |
| Region | Central India |
| Image | Ubuntu Server 22.04 LTS |
| Size | Standard_B1s or any appropriate size |
| Authentication | Username & Password or SSH Key |

### Networking Tab

Go to the `Networking` tab and fill in the following details:

| Field | Value |
|---|---|
| Virtual Network | AppGateway-VNet |
| Subnet | VM-Subnet |
| Public IP | None |
| NIC Network Security Group | Basic or None |

> Note: Public IP is set to `None` because NAT Gateway will be used later.

4. Click `Review + Create`.
5. Click `Create`.

---

### Step 4: Create VM 2 - Organic App

Repeat the same steps used for VM 1, but use the following VM name:

| Field | Value |
|---|---|
| VM Name | VM-Organic |

Use the same settings as VM 1 for the remaining configuration.
