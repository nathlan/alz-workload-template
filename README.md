# [Workload Name] - Azure Landing Zone

> **Note:** This repository was created from the ALZ workload template. Update this README with your workload-specific information.

## Overview

This repository contains the Infrastructure as Code (Terraform) for the `[workload-name]` Azure Landing Zone.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # CI/CD workflow for Terraform
├── terraform/
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Outputs
│   └── terraform.tf                # Provider and backend config
├── .gitignore                      # Git ignore patterns
└── README.md                       # This file
```

## Deployment Workflow

This repository uses a parent/child workflow pattern:
- **Parent workflow:** `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml` (reusable)
- **Child workflow:** `.github/workflows/terraform-deploy.yml` (this repo)

### Workflow Triggers

- **Pull Requests:** Validates, scans, and plans changes (no apply)
- **Push to main:** Deploys to production with manual approval gate
- **Manual dispatch:** Allows selecting environment for deployment

## Getting Started

### 1. Configure Repository Secrets

Add these secrets in **Settings → Secrets and variables → Actions**:

```
AZURE_CLIENT_ID       - Service principal client ID (OIDC)
AZURE_TENANT_ID       - Azure tenant ID
AZURE_SUBSCRIPTION_ID - Azure subscription ID
```

### 2. Create Environment

Create a **production** environment in **Settings → Environments**:
- Enable "Required reviewers" and add platform team members
- Optionally configure deployment branches (e.g., only main)
- Add the same secrets as above at the environment level

### 3. Configure Terraform Backend

Update `terraform/terraform.tf` with your backend configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "[workload-name]-production.tfstate"
    use_oidc             = true
  }
}
```

### 4. Add Your Infrastructure Code

Add your Terraform resources to the `terraform/` directory:
- Use `main.tf` for resource definitions
- Define variables in `variables.tf`
- Expose outputs in `outputs.tf`

### 5. Create a Pull Request

1. Create a feature branch
2. Add your Terraform changes
3. Push and create a PR
4. Review the Terraform plan in PR comments
5. Get approval from the platform team
6. Merge to trigger deployment

## Azure OIDC Setup

If not already configured, set up Azure OIDC for this repository:

```bash
# Get the App Registration ID
APP_ID="<your-app-id>"
REPO_NAME="<this-repo-name>"

# Add federated credential for this repository
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-${REPO_NAME}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:nathlan/${REPO_NAME}:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- Reference the ALZ vending documentation in `nathlan/.github-private`

## Related Repositories

- **ALZ Subscriptions:** `nathlan/alz-subscriptions` - Subscription vending infrastructure
- **Reusable Workflows:** `nathlan/.github-workflows` - Central workflow definitions
- **LZ Vending Module:** `nathlan/terraform-azurerm-landing-zone-vending`