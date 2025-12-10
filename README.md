# Azure Enterprise DR & Infrastructure Automation Framework

![Azure](https://img.shields.io/badge/Cloud-Azure-0078D4?logo=microsoft-azure&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Config-Ansible-EE0000?logo=ansible&logoColor=white)
![PowerShell](https://img.shields.io/badge/Automation-PowerShell-5391FE?logo=powershell&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success)

## 📋 Executive Summary
This repository houses a comprehensive **Infrastructure & Disaster Recovery (DR) Framework** designed for enterprise Azure environments. It unifies Infrastructure as Code (Terraform), Configuration Management (Ansible), and Recovery Automation (PowerShell) into a single pipeline.

The framework is engineered to solve three critical challenges:
1.  **Drift-Free Infrastructure:** Enforcing identical configurations across Production and DR environments using modular IaC.
2.  **Automated Failover:** Reducing Recovery Time Objective (RTO) by **60%** via scripted cross-region/cross-subscription VM restoration.
3.  **Day-2 Operations:** Automating post-provisioning configuration and patch management using Ansible playbooks.

## 🏗️ High-Level Architecture
The solution follows a **Hub-and-Spoke** network topology, implementing a "Cold Standby" DR strategy to optimize costs.

## 📂 Repository Structure
The project is organized to enforce Separation of Concerns, ensuring scalability as the infrastructure grows.

```
azure-dr-automation-framework/
├── terraform/                # INFRASTRUCTURE LAYER
│   ├── deploy/               # Root configuration (Single Source of Truth)
│   ├── env/                  # Environment-specific instantiations (Prod/DR)
│   └── modules/              # Reusable components (Compute, Network, KeyVault)
│
├── ansible/                  # CONFIGURATION LAYER
│   ├── playbooks/            # YAML tasks for Nginx, Docker, & Security hardening
│   ├── roles/                # Modular Ansible roles
│   └── inventory/            # Dynamic Azure inventory
│
├── scripts/                  # AUTOMATION LAYER
│   ├── dr_restore.ps1        # Core Logic: Cross-Region/Cross-Sub VM Restoration
│   └── health_check.ps1      # Post-restoration validation
│
└── README.md                 # Framework Documentation
```

## 🚀 Key Capabilities
1. Infrastructure as Code (Terraform)
Symlink Deployment Pattern: Utilizes a central deploy/main.tf linked to environment folders (env/prod, env/dr). This ensures that any architectural change automatically propagates to all environments, eliminating "Snowflake" servers.

Modular Design: Custom-built modules for virtual_network, storage_account, and recovery_services_vault with embedded security defaults (NSGs, Encryption).

State Management: Remote state locking via Azure Blob Storage prevents race conditions in team environments.

2. Disaster Recovery Automation (PowerShell)
Cross-Subscription Restoration: Capable of restoring critical workloads from a "Backup/Management" subscription directly into a "DR" subscription.

Idempotency Checks: The dr_restore.ps1 engine intelligently detects existing or in-progress restore jobs, preventing conflicts during high-stress drills.

Dynamic Naming: Automatically transforms resource names (e.g., appending -WUS or -DR) to adhere to compliance standards during failover.

3. Configuration Management (Ansible)
Post-Provisioning Setup: Automatically installs monitoring agents (Datadog/Log Analytics) and configures web servers (Nginx/Apache) immediately after a VM is restored or provisioned.

## 💻 Usage Guide
### A. Provisioning Infrastructure
Initialize and apply the Terraform configuration for the DR environment:

```
cd terraform/env/dr
terraform init
terraform plan -out=dr.tfplan
terraform apply dr.tfplan
```

### B. Configuring Servers
Run Ansible playbooks to configure the newly provisioned VMs:

```
cd ansible
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml

```

### C. Executing Disaster Recovery
Trigger the failover of a specific application server to the West US region:

### PowerShell

```
./scripts/dr_restore.ps1 `
    -SourceResourceGroupName "rg-prod-eastus" `
    -TargetResourceGroupName "rg-dr-westus" `
    -VMName "app-server-01" `
    -UseSecondaryRegion $true
```

### 🛡️ Security & Compliance
Secret Management: No credentials are stored in code. All secrets are fetched dynamically from Azure Key Vault during runtime.

Least Privilege: Scripts utilize Service Principals with scoped RBAC roles (Backup Operator, Virtual Machine Contributor) rather than broad Admin access.
