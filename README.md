# microsite-deployment

This repository contains the deployment assets for *microsites* (devops portals,
blogs, documentation sites, etc.) hosted as static websites on Azure Blob Storage.
It is consumed by an Octopus Deploy pipeline that provisions infrastructure and
then syncs built site content.

## Repository structure

```
terraform/                      # Infrastructure-as-code (Terraform)
│   backend.tf                  # Remote state backend (Azure Blob Storage)
│   main.tf                     # Provider, data sources, and resources
│   outputs.tf                  # Exposes the static website endpoint URL
│   variables.tf                # Input variables (injected by Octopus Deploy)
│
microsite-deployment-script/    # Content deployment
    Deploy-Microsite.ps1        # Syncs built site package to the $web container
```

---

## Prerequisites

1. [Terraform](https://www.terraform.io/) v1.0 or later.
2. An existing Azure resource group in the target subscription.
3. An Azure service principal configured for OIDC, with:
   - `Contributor` (or scoped equivalent) on the target subscription for resource deployment.
   - `Storage Blob Data Contributor` on the Terraform state storage account.
4. [AzCopy](https://learn.microsoft.com/azure/storage/common/storage-use-azcopy-v10) available on the deployment worker for the content sync step.
5. Octopus Deploy project configured with the variables listed below.

---

## Octopus Deploy variables

| Variable | Used by | Purpose |
|---|---|---|
| `Microsite.Azure.SubscriptionId` | Terraform | Target subscription for resource deployment |
| `Microsite.Azure.ResourceGroupName` | Terraform | Existing resource group for the storage account |
| `Microsite.Azure.StorageAccountName` | Terraform + script | Name of the static website storage account |
| `Microsite.Azure.ResourceLocation` | Terraform | Azure region (e.g. `westus`) |
| `Terraform.Backend.StorageAccountName` | Terraform | Storage account holding Terraform state |
| `Terraform.Backend.ContainerName` | Terraform | Blob container for state files |
| `Terraform.Backend.StateKey` | Terraform | Path to the state file, e.g. `microsites/preprod/pr42/terraform.tfstate` |

> The `#{...}` octostache placeholders in `terraform/variables.tf` and
> `terraform/backend.tf` are substituted by Octopus before Terraform runs,
> so no sensitive data or environment-specific values are stored in source control.

---

## Terraform

### Backend

State is stored in Azure Blob Storage (`terraform/backend.tf`). Authentication
uses OIDC — no access keys or SAS tokens are required. The `#{...}` placeholders
are substituted by Octopus at deploy time.

### Resources provisioned

- **`azurerm_storage_account`** — Standard LRS storage account.
- **`azurerm_storage_account_static_website`** — Enables the `$web` container,
  serving `index.html` as the default document and `404.html` for missing paths.

### Outputs

| Output | Description |
|---|---|
| `static_website_url` | Primary endpoint URL for the static website |

### Octopus step working directory

The Terraform step in Octopus must set its working directory to `terraform/`
(relative to the repository root) so that `terraform init` and `apply` run
against the correct files.

### Running locally

Copy `terraform/variables.tf` defaults as a guide and supply real values via
`-var` flags or a `terraform.tfvars` file (git-ignored):

```bash
cd terraform
terraform init
terraform plan -var="subscription_id=..." -var="storage_account_name=..." ...
```

---

## Content deployment

`microsite-deployment-script/Deploy-Microsite.ps1` is run as an Octopus
**Run a Script** step after Terraform. It uses AzCopy with Azure CLI
authentication to sync a built site package to the storage account's `$web`
container.
