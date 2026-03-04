# microsite-terraform

This repository contains Terraform configuration for deploying the
infrastructure used by *microsites* (devops portals, blogs, documentation
sites, etc.) on Azure.  It is intentionally small: the only resources
created are an existing resource group data lookup, a storage account and
enabled static website support.

The module is designed to be run from an Octopus Deploy pipeline where
values for variables are injected at runtime using [octostache syntax](https://octopus.com/docs/projects/variables/variable-syntax).

---

## Prerequisites

1. [Terraform](https://www.terraform.io/) v1.0 or later installed.
2. An Azure subscription with permissions to create a storage account.
3. An existing resource group where the storage account will be placed.
4. Octopus Deploy project configured with the following variables,
   or supplied by another mechanism:
   - `Microsite.Azure.StorageAccountName`
   - `Microsite.Azure.ResourceGroupName`
   - `Microsite.Azure.SubscriptionId`
   - `Microsite.Azure.ResourceLocation`
   - `Terraform.Backend.StorageAccountName`
   - `Terraform.Backend.ContainerName`
   - `Terraform.Backend.StateKey`

> ⚠️ The defaults for most inputs and the backend configuration use
> octostache placeholders such as `#{Variable.Name}`. Octopus replaces
> these before running `terraform init`/`apply`, so no sensitive data is
> checked in to version control.

## Variables

All of the input variables have sane defaults that resolve to Octopus
variables at runtime. You can override them in your Terraform CLI
commands or using a `terraform.tfvars` file if you run locally.

```hcl
variable "storage_account_name" {
  type        = string
  default = "#{Microsite.Azure.StorageAccountName}"
  description = "Name of the Azure Storage Account."
}
# ... (other variables are defined in variables.tf)
```

Refer to `variables.tf` for the full list and descriptions.

## Backend Configuration

State is stored in an Azure Blob Storage backend.  The
`backend.tf` file looks like this:

```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "#{Terraform.Backend.StorageAccountName}"
    container_name       = "#{Terraform.Backend.ContainerName}"
    key                  = "#{Terraform.Backend.StateKey}"
    use_oidc             = true
    use_azuread_auth     = true
  }
}
```

Octopus substitutes the `#{...}` placeholders with project variables
at deployment time.  Authentication uses OIDC and the same service
principal defined in `main.tf`.

## Outputs

`outputs.tf` exposes the static website endpoint URL:

```hcl
output "static_website_url" {
  description = "Primary endpoint URL for the Azure Storage static website."
  value       = azurerm_storage_account.static_site.primary_web_endpoint
}
```

## Usage

A typical Octopus step would run:

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

When running locally you will need to provide real values for the
variables, either via `-var` flags or a `terraform.tfvars` file.

## Notes

- The resource group is expected to already exist; Terraform only reads
  it via a `data` block.
- Storage account must have a globally unique name.
- The configuration enables static website hosting, serving `index.html`
  and `404.html`.

---
