# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# Creacion de rg y storage para tfstate del proyecto completo
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "state_rg" {
  name     = "rg-terraform-state"
  location = "eastus"

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------------------------
# Storage Account
# ------------------------------------------------------------------------------------------------

resource "azurerm_storage_account" "state_storage" {
  name                     = "sttfstatemongo01"
  resource_group_name     = azurerm_resource_group.state_rg.name
  location                 = azurerm_resource_group.state_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------------------------
# Container
# ------------------------------------------------------------------------------------------------

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state_storage.id
}

# ------------------------------------------------------------------------------------------------
# Lock for Delete action on RG
# ------------------------------------------------------------------------------------------------

resource "azurerm_management_lock" "state_lock" {
  name       = "lock-terraform-state"
  scope      = azurerm_resource_group.state_rg.id
  lock_level = "CanNotDelete"
  notes      = "Protege el backend de Terraform. Requiere remover el lock manualmente antes de poder destruir."
}
