terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.2"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc        = true
  subscription_id = var.subscription_id
}

# Import the existing resource group
data "azurerm_resource_group" "microsite" {
  name = var.resource_group_name
}

# Create Storage Account
resource "azurerm_storage_account" "static_site" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.microsite.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Restrict Azure Files SMB access to the "Maximum security" profile
  # (SMB 3.1.1, Kerberos only, AES-256). Microsites don't use file shares,
  # but legacy SMB protocols must be disabled on every account.
  share_properties {
    smb {
      versions                        = ["SMB3.1.1"]
      authentication_types            = ["Kerberos"]
      kerberos_ticket_encryption_type = ["AES-256"]
      channel_encryption_type         = ["AES-256-GCM"]
    }
  }
}

# Enables the $web blob container and configures the default document and the
# custom 404 page served by Azure's static website endpoint.
resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.static_site.id
  index_document     = "index.html"
  error_404_document = "404.html"
}
