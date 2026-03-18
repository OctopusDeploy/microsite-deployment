terraform {
  # Remote backend — Azure Blob Storage
  #
  # The #{...} placeholders are Octopus Deploy variable references. Octopus
  # substitutes real values into this file before running `terraform init`,
  # so no credentials or environment-specific values are stored in source
  # control.
  #
  # Authentication uses OIDC (same service principal as the provider — see
  # main.tf). The SP must have the "Storage Blob Data Contributor" role on
  # the state storage account. No access keys or SAS tokens are required.
  backend "azurerm" {
    storage_account_name = "#{Terraform.Backend.StorageAccountName}"
    container_name       = "#{Terraform.Backend.ContainerName}"
    key                  = "#{Terraform.Backend.StateKey}"
    use_azuread_auth     = true
  }
}