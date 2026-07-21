# providers.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.9.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

}


# Configuración del proveedor
provider "azurerm" {
  features {}
}