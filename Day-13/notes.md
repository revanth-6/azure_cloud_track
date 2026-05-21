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

## Phase 4: NAT Gateway

### Step 5: Create NAT Gateway for VMs to Access Internet

1. Search for `NAT Gateways` in the search bar.
2. Click `+ Create`.

### Basics Tab

Fill in the following details:

| Field | Value |
|---|---|
| Resource Group | AppGateway-RG |
| Name | AppGateway-NAT |
| Region | Central India |
| Idle Timeout | 4 minutes |

### Outbound IP Tab

1. Go to the `Outbound IP` tab.
2. Click `Create a new public IP address`.
3. Enter the following details:

| Field | Value |
|---|---|
| Name | NAT-PublicIP |

### Subnet Tab

1. Go to the `Subnet` tab.
2. Select the following details:

| Field | Value |
|---|---|
| Virtual Network | AppGateway-VNet |
| Subnet | VM-Subnet |

> Note: NAT Gateway should be associated with the VM subnet so that the VMs can access the internet without having their own public IP addresses.

3. Click `Review + Create`.
4. Click `Create`.

---

## Phase 5: Network Security Groups NSGs

### Step 6: Create NSG for VM Subnet

1. Search for `Network Security Groups` in the search bar.
2. Click `+ Create`.
3. Fill in the following details:

| Field | Value |
|---|---|
| Resource Group | AppGateway-RG |
| Name | VM-Subnet-NSG |
| Region | Central India |

4. Click `Review + Create`.
5. Click `Create`.

---

### Step 7: Configure Inbound Rules for VM NSG

1. Open `VM-Subnet-NSG`.
2. Go to `Inbound Security Rules`.
3. Click `+ Add`.

Add the following inbound security rules:

| Priority | Name | Source | Source Port | Destination | Destination Port | Protocol | Action |
|---|---|---|---|---|---|---|---|
| 100 | Allow-HTTP | Any | * | Any | 80 | TCP | Allow |
| 110 | Allow-SSH | Any | * | Any | 22 | TCP | Allow |

4. Click `Save`.

---

### Step 8: Associate NSG with VM Subnet

1. Open `VM-Subnet-NSG`.
2. Go to `Subnets`.
3. Click `+ Associate`.
4. Select the following details:

| Field | Value |
|---|---|
| Virtual Network | AppGateway-VNet |
| Subnet | VM-Subnet |

5. Click `OK`.

---

### Step 9: Create and Configure NSG for Application Gateway Subnet

1. Repeat Step 6 to create another NSG.
2. Use the following name:

| Field | Value |
|---|---|
| Name | AppGW-Subnet-NSG |

3. Open `AppGW-Subnet-NSG`.
4. Go to `Inbound Security Rules`.
5. Click `+ Add`.

Add the following inbound security rules:

| Priority | Name | Source | Source Port | Destination | Destination Port | Protocol | Action |
|---|---|---|---|---|---|---|---|
| 100 | Allow-HTTP | Any | * | Any | 80 | TCP | Allow |
| 110 | Allow-HTTPS | Any | * | Any | 443 | TCP | Allow |
| 120 | Allow-GatewayManager | GatewayManager | * | Any | 65200-65535 | TCP | Allow |

> Note: The `65200-65535` port range rule is mandatory for Application Gateway to function. Azure uses these ports for health probes and internal communication.

6. Associate this NSG with `AppGateway-Subnet`.

---

## Phase 6: Install Applications on VMs

### Step 10: Install Fitness App on VM-Fitness

1. Connect to `VM-Fitness` using SSH or Azure Bastion.
2. Run the following commands:

```bash
sudo apt update -y
sudo apt install apache2 -y
sudo mkdir -p /var/www/html/fitness
echo "<h1>Welcome to Fitness App</h1>" | sudo tee /var/www/html/fitness/index.html
```

3. Configure Apache to serve the application on the /fitness path, or use whichever setup you configured.

### Step 11: Install Organic App on VM-Organic

1. Connect to VM-Organic using SSH or Azure Bastion.
2. Run the following commands:

```bash
sudo apt update -y
sudo apt install apache2 -y
sudo mkdir -p /var/www/html/organic
echo "<h1>Welcome to Organic App</h1>" | sudo tee /var/www/html/organic/index.html
```
