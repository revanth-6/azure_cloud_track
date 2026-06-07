# Block 1: Azure Foundation and Networking

## Covers:

- Azure Compute and CLI
- VM creation
- Azure CLI and PowerShell
- VNet
- Subnets
- IP addressing
- NSG
- ASG
- Bastion
- Firewall
- Route tables
- NAT Gateway
- Load Balancer
- Application Gateway
- DNS
- Hub and Spoke
- VNet Peering

This is the most important block.

If your networking foundation is weak, everything else in Azure will feel confusing.

You should become very strong in:

- Resource Group
- Region
- Subscription
- VNet
- Subnet
- NIC
- Private IP
- Public IP
- NSG
- Route Table
- NAT Gateway
- Load Balancer
- Application Gateway
- Bastion
- Firewall
- DNS Zone
- Private DNS Zone
- VNet Peering

## Your target:

You should be able to draw and explain a secure 3-tier Azure architecture from memory.

### Example:

```text
Internet
→ Application Gateway
→ Public Subnet
→ Private App Subnet
→ Private DB Subnet
→ Bastion for admin access
→ NAT Gateway for outbound internet
→ NSG rules for traffic control
→ Private DNS for internal resolution
```

If you can explain this clearly, you are already ahead of many beginners.
