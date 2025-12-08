# Terraform Infrastructure Automation

## Overview

This repository contains an Infrastructure-as-Code (IaC) implementation using Terraform to provision and manage Azure cloud resources.

The project is designed with a modular architecture, enabling reusability, scalability, and clear separation of responsibilities.

The structure supports deployment from a single environment directory, making it easy to execute plan/apply commands without navigating across modules.

This repository demonstrates skills in:

- Terraform module development
- Azure infrastructure provisioning
- Environment-based deployments
- Infrastructure design and organization
- Automation and DR (Disaster Recovery)
- Reusable, scalable IaC practices

## Repository Structure
.
├── deploy
│   ├── main.tf
│   └── variables.tf
├── env
│   ├── main.tf -> ../deploy/main.tf
│   ├── modules -> ../modules/
│   ├── provider.tf
│   ├── terraform.tfvars
│   └── variables.tf -> ../deploy/variables.tf
└── modules
    ├── key_vault
    ├── private_dns
    ├── recovery_services_vault
    ├── resource_group
    ├── storage_account
    ├── virtual_machine
    └── virtual_network

## Key Directories

1. modules/

Contains reusable Terraform modules, each encapsulating a specific Azure resource:

2. deploy/

Contains the root Terraform configuration that brings all modules together and defines how they interact.

- main.tf – Calls all modules and sets up dependencies
- variables.tf – Centralized variable definitions

This folder defines the infrastructure blueprint.

3. env/

Environment-specific entry point for deployments.

Contents include:

- A symlink to deploy/main.tf
- A symlink to deploy/variables.tf
- A reference to modules directory
- Environment-specific provider.tf
- Environment-specific terraform.tfvars

This allows you to plan and apply from env/ without changing module paths.

## Prerequisites

- erraform v1.3+
- Azure CLI installed and authenticated
- Sufficient permissions on Azure Subscription