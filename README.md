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
AZURE_CLIENT_ID_PLAN  - User-Assigned Managed Identity Client ID for plan (Reader role)
AZURE_CLIENT_ID_APPLY - User-Assigned Managed Identity Client ID for apply (Owner role)
AZURE_TENANT_ID       - Azure tenant ID
AZURE_SUBSCRIPTION_ID - Azure subscription ID
```

**Security Model: Least Privilege**
- **Plan Identity (Reader):** Used for `terraform init` and `terraform plan` operations. Has read-only access to assess changes.
- **Apply Identity (Owner):** Used for `terraform apply` operations. Has full access to create, modify, and delete resources.

This separation ensures that plan operations cannot accidentally modify infrastructure.

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

This repository uses **User-Assigned Managed Identities (UAMIs)** with federated credentials for secure, passwordless authentication to Azure.

### Setup Two Managed Identities

You need to create TWO separate managed identities with federated credentials:

#### 1. Plan Identity (Reader Role)

```bash
# Create User-Assigned Managed Identity for plan operations
RESOURCE_GROUP="rg-github-identities"
PLAN_IDENTITY_NAME="uami-github-${REPO_NAME}-plan"

az identity create \
  --resource-group $RESOURCE_GROUP \
  --name $PLAN_IDENTITY_NAME

# Get the client ID
PLAN_CLIENT_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $PLAN_IDENTITY_NAME \
  --query clientId -o tsv)

# Assign Reader role at subscription scope
az role assignment create \
  --assignee $PLAN_CLIENT_ID \
  --role Reader \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"

# REQUIRED: Assign Storage Blob Data Contributor on the Terraform state container
# Without this role, terraform init will fail with a 403 Forbidden error
STATE_STORAGE_ID=$(az storage account show \
  --resource-group rg-terraform-state \
  --name stterraformstate \
  --query id -o tsv)

az role assignment create \
  --assignee $PLAN_CLIENT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "${STATE_STORAGE_ID}/blobServices/default/containers/tfstate"

# Add federated credential for GitHub Actions
az identity federated-credential create \
  --identity-name $PLAN_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "github-${REPO_NAME}-plan" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:nathlan/${REPO_NAME}:environment:production" \
  --audiences "api://AzureADTokenExchange"
```

#### 2. Apply Identity (Owner Role)

```bash
# Create User-Assigned Managed Identity for apply operations
APPLY_IDENTITY_NAME="uami-github-${REPO_NAME}-apply"

az identity create \
  --resource-group $RESOURCE_GROUP \
  --name $APPLY_IDENTITY_NAME

# Get the client ID
APPLY_CLIENT_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $APPLY_IDENTITY_NAME \
  --query clientId -o tsv)

# Assign Owner role at subscription scope
az role assignment create \
  --assignee $APPLY_CLIENT_ID \
  --role Owner \
  --scope "/subscriptions/${SUBSCRIPTION_ID}"

# REQUIRED: Assign Storage Blob Data Contributor on the Terraform state container
az role assignment create \
  --assignee $APPLY_CLIENT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "${STATE_STORAGE_ID}/blobServices/default/containers/tfstate"

# Add federated credential for GitHub Actions
az identity federated-credential create \
  --identity-name $APPLY_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "github-${REPO_NAME}-apply" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:nathlan/${REPO_NAME}:environment:production" \
  --audiences "api://AzureADTokenExchange"
```

#### 3. Add Client IDs to GitHub Secrets

```bash
# Add the plan identity client ID
gh secret set AZURE_CLIENT_ID_PLAN --body "$PLAN_CLIENT_ID" --repo nathlan/${REPO_NAME}

# Add the apply identity client ID
gh secret set AZURE_CLIENT_ID_APPLY --body "$APPLY_CLIENT_ID" --repo nathlan/${REPO_NAME}
```

> **Note:** The Terraform state storage account may reside in a different tenant or subscription from the one being deployed to. In that case, ensure federated credentials are configured against the correct tenant, and that the storage account allows Microsoft Entra ID authentication (not key-only access).

### Benefits of UAMIs

- ✅ **No stored credentials** - Client IDs are not sensitive
- ✅ **Least privilege** - Plan uses read-only, apply uses elevated permissions
- ✅ **Audit trail** - Each identity's actions tracked separately in Azure
- ✅ **Defense in depth** - Compromised plan job cannot modify infrastructure

## Validating OIDC Configuration

Before running the full workflow, you can validate that OIDC authentication is working correctly.

### 1. Check OIDC Subject Template

GitHub Actions uses a subject claim (`sub`) in the OIDC token to identify the workflow context. Verify the repository uses the default subject format:

```bash
gh api repos/nathlan/${REPO_NAME}/actions/oidc/customization/sub
```

The default response is:
```json
{ "use_default": true }
```

If your federated credentials use the default subject format (`repo:<org>/<repo>:environment:<env>`), this is the expected output.

### 2. Verify Federated Credentials

Confirm each UAMI has the correct federated credentials matching the GitHub Actions subject:

```bash
# Check plan identity federated credentials
az identity federated-credential list \
  --identity-name "uami-github-${REPO_NAME}-plan" \
  --resource-group rg-github-identities \
  --query "[].{name:name,subject:subject,issuer:issuer}" \
  -o table

# Check apply identity federated credentials
az identity federated-credential list \
  --identity-name "uami-github-${REPO_NAME}-apply" \
  --resource-group rg-github-identities \
  --query "[].{name:name,subject:subject,issuer:issuer}" \
  -o table
```

The `subject` field must match the exact claim GitHub sends. For environment-scoped workflows, this is:
```
repo:nathlan/<repo-name>:environment:production
```

### 3. Verify Storage Account Permissions

Confirm both UAMIs have the required role on the Terraform state storage container:

```bash
STATE_STORAGE_ID=$(az storage account show \
  --resource-group rg-terraform-state \
  --name stterraformstate \
  --query id -o tsv)

# List role assignments on the container
az role assignment list \
  --scope "${STATE_STORAGE_ID}/blobServices/default/containers/tfstate" \
  --query "[].{principal:principalName,role:roleDefinitionName}" \
  -o table
```

Both UAMIs should appear with `Storage Blob Data Contributor`.

### 4. Test Terraform Init Manually

To test `terraform init` with a specific UAMI before running the full workflow, trigger a manual workflow run (`workflow_dispatch`) from the GitHub Actions tab. The OIDC token is only available within a GitHub Actions runner and cannot be replicated locally.

For a quick smoke test, create a short-lived test branch, push a minor change to `terraform/`, and observe the validate job in the Actions tab. If the job reaches the `Terraform Init` step without a 403, OIDC backend access is working.

## Troubleshooting

### 403 Forbidden During `terraform init`

**Symptom:** `terraform init` fails with `AuthorizationPermissionMismatch` or `403 Forbidden` when accessing the storage account.

**Causes and fixes:**

| Cause | Fix |
|-------|-----|
| UAMI missing `Storage Blob Data Contributor` on the state container | Assign the role as shown in the [Plan Identity setup](#1-plan-identity-reader-role) above |
| Storage account has "Allow Microsoft Entra ID authentication only" disabled | Enable it: `az storage account update --name stterraformstate --resource-group rg-terraform-state --allow-shared-key-access false` |
| Federated credential subject mismatch | Verify the subject in the credential matches the GitHub Actions OIDC token claim exactly |
| Wrong tenant in backend config | Ensure the backend `tenant_id` (if set) matches the tenant where the storage account lives |

**Quick diagnosis:**

```bash
# Check if the storage account blocks public access or key-based auth
az storage account show \
  --name stterraformstate \
  --resource-group rg-terraform-state \
  --query "{publicAccess:publicNetworkAccess,sharedKeyAccess:allowSharedKeyAccess,defaultAction:networkRuleSet.defaultAction}" \
  -o json
```

### OIDC Token Exchange Fails

**Symptom:** `Error: AADSTS70021` or `no matching federated identity record found`.

**Fix:** The federated credential `subject` must exactly match the OIDC token claim. Common mismatches:
- Using `ref:refs/heads/main` subject when the workflow uses an environment (`environment:production`)
- Typo in the repository name or organisation name

Verify the exact claim GitHub sends by inspecting the workflow run's OIDC token subject in the run logs.

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- Reference the ALZ vending documentation in `nathlan/.github-private`

## Related Repositories

- **ALZ Subscriptions:** `nathlan/alz-subscriptions` - Subscription vending infrastructure
- **Reusable Workflows:** `nathlan/.github-workflows` - Central workflow definitions
- **LZ Vending Module:** `nathlan/terraform-azurerm-landing-zone-vending`