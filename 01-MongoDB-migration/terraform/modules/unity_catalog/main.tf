
# ------------------------------------------------------------------------------------------------
# Specific provider for Databricks
# ------------------------------------------------------------------------------------------------

  # 2. Definimos el Provider de forma dinámica
  provider "databricks" {
  alias = "workspace"
  
  
  host                        = try(var.databricks_workspace_url, "")
  azure_workspace_resource_id = try(var.databricks_workspace_id, "")
  
  auth_type = "azure-cli"
}


# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# Databriks Unity Catalog
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------

# 1. Access Connector
resource "azurerm_databricks_access_connector" "uc_connector" {
  name                = "dbac-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  identity { type = "SystemAssigned" }
}

resource "azurerm_role_assignment" "uc_connector_storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.uc_connector.identity[0].principal_id
}

# 2. Storage Credential
resource "databricks_storage_credential" "uc_credential" {
  provider = databricks.workspace
  name     = "cred-${var.project_name}"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.uc_connector.id
  }
  lifecycle {
    prevent_destroy = false
  }
}

# 3. External Locations
resource "databricks_external_location" "uc_ext_loc_silver" {
  provider        = databricks.workspace
  name            = "ext-loc-${var.project_name}-silver-01"
  url             = var.storage_account_silver_url
  credential_name = databricks_storage_credential.uc_credential.id
  lifecycle {
    prevent_destroy = false
  }
}


resource "databricks_external_location" "uc_ext_loc_bronze" {
  provider        = databricks.workspace
  name            = "ext-loc-${var.project_name}-bronze-01"
  url             = var.storage_account_bronze_url
  credential_name = databricks_storage_credential.uc_credential.id
  lifecycle {
    prevent_destroy = false
  }
}


resource "databricks_external_location" "uc_ext_loc_gold" {
  provider        = databricks.workspace
  name            = "ext-loc-${var.project_name}-gold-01"
  url             = var.storage_account_gold_url
  credential_name = databricks_storage_credential.uc_credential.id
  lifecycle {
    prevent_destroy = false
  }
}


resource "databricks_external_location" "uc_ext_loc_control" {
  provider        = databricks.workspace
  name            = "ext-loc-${var.project_name}-control"
  url             = var.storage_account_control_url
  credential_name = databricks_storage_credential.uc_credential.id
  lifecycle {
    prevent_destroy = false
  }
}


# ------------------------------------------------------------------------------------------------
# 4. Catalogs (Data Mesh - Dominios Lógicos Separados)
# ------------------------------------------------------------------------------------------------

resource "databricks_catalog" "catalog_logistics" {
  provider      = databricks.workspace
  name          = "catalog_logistics"
  comment       = "Dominio logístico para orders, order_items y deliveries"
  storage_root  = "${var.storage_account_silver_url}catalog_logistics"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [databricks_external_location.uc_ext_loc_silver]
}

resource "databricks_catalog" "catalog_commercial" {
  provider      = databricks.workspace
  name          = "catalog_commercial"
  comment       = "Dominio comercial para customers, sellers y reviews"
  storage_root  = "${var.storage_account_silver_url}catalog_commercial"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [databricks_external_location.uc_ext_loc_silver]
}

resource "databricks_catalog" "catalog_catalog" {
  provider      = databricks.workspace
  name          = "catalog_catalog"
  comment       = "Dominio de catálogo para la colección de products"
  storage_root  = "${var.storage_account_silver_url}catalog_catalog"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    databricks_external_location.uc_ext_loc_silver,
    databricks_external_location.uc_ext_loc_bronze,
    databricks_external_location.uc_ext_loc_gold
  ]
}

# ------------------------------------------------------------------------------------------------
# 5. Schemas (Logic layers under the catalog using for_each)
# ------------------------------------------------------------------------------------------------

locals {
  schemas_config = {
    "logistics_silver" = {
      catalog_name = databricks_catalog.catalog_logistics.name
      schema_name  = "silver"
      storage_url  = var.storage_account_silver_url
      ext_loc_dep  = databricks_external_location.uc_ext_loc_silver.id
      comment      = "Capa silver para el dominio logístico"
    }
    "logistics_gold" = {
      catalog_name = databricks_catalog.catalog_logistics.name
      schema_name  = "gold"
      storage_url  = var.storage_account_gold_url
      ext_loc_dep  = databricks_external_location.uc_ext_loc_gold.id
      comment      = "Capa gold para el dominio logístico"
    }
    "commercial_silver" = {
      catalog_name = databricks_catalog.catalog_commercial.name
      schema_name  = "silver"
      storage_url  = var.storage_account_silver_url
      ext_loc_dep  = databricks_external_location.uc_ext_loc_silver.id
      comment      = "Capa silver para el dominio comercial"
    }
    "commercial_gold" = {
      catalog_name = databricks_catalog.catalog_commercial.name
      schema_name  = "gold"
      storage_url  = var.storage_account_gold_url
      ext_loc_dep  = databricks_external_location.uc_ext_loc_gold.id
      comment      = "Capa gold para el dominio comercial"
    }
    "catalog_silver" = {
      catalog_name = databricks_catalog.catalog_catalog.name
      schema_name  = "silver"
      storage_url  = var.storage_account_silver_url
      ext_loc_dep  = databricks_external_location.uc_ext_loc_silver.id
      comment      = "Capa silver para el dominio de productos"
    }
    "catalog_gold" = {
      catalog_name = databricks_catalog.catalog_catalog.name
      schema_name  = "gold"
      storage_url  = var.storage_account_gold_url
      ext_loc_dep  = databricks_external_location.uc_ext_loc_gold.id
      comment      = "Capa gold para el dominio de productos"
    }
  }
}

resource "databricks_schema" "domain_schemas" {
  for_each = local.schemas_config

  provider     = databricks.workspace
  catalog_name = each.value.catalog_name
  name         = each.value.schema_name
  storage_root = each.value.storage_url
  comment      = each.value.comment

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      storage_root
    ]
  }

  depends_on = [
    databricks_catalog.catalog_logistics,
    databricks_catalog.catalog_commercial,
    databricks_catalog.catalog_catalog
  ]
}