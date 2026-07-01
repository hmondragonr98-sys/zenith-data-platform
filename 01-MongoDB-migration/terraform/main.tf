# Configuración del proveedor
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group: El contenedor lógico de tu proyecto
resource "azurerm_resource_group" "rg_migration" {
  name     = "rg-mongodb-migration"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "stmongodbdatamigrate01" # ¡Cambia esto por algo único!
  resource_group_name      = azurerm_resource_group.rg_migration.name
  location                 = azurerm_resource_group.rg_migration.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally-redundant storage (el más económico)
  is_hns_enabled           = true

  tags = {
    environment = "dev"
    project     = "mongodb-migration"
  }
}

resource "azurerm_storage_container" "data_container" {
  name                  = "mongodb-data"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
