# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# adf.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------
# data Factory Workspace
# ------------------------------------------------------------------------------------------------

# 1. ADF (Recibe RG y storage_account_id por variable)
resource "azurerm_data_factory" "adf" {
  name                            = "adf-${var.project_name}-${var.environment}-01"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  managed_virtual_network_enabled = true
  
  identity {
    type = "SystemAssigned"
  }
}


# ------------------------------------------------------------------------------------------------
# Self Hosted Interation Runtimes
# ------------------------------------------------------------------------------------------------

# 2. SHIR - On-Premisse
resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  name                = "shir-mongo-migration"
  data_factory_id     = azurerm_data_factory.adf.id
}

#3. SHIR - VPN connection
resource "azurerm_data_factory_integration_runtime_azure" "ir_managed_vnet" {
  name                    = "azure-ir-vnet"
  data_factory_id         = azurerm_data_factory.adf.id
  location                = var.location
  virtual_network_enabled = true
}

# ------------------------------------------------------------------------------------------------
# Monitoring Data Factory
# ------------------------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "adf_diagnostics" {
  name                       = "diag-adf-to-law"
  target_resource_id         = azurerm_data_factory.adf.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Logs específicos de ADF
  enabled_log {
    category = "PipelineRuns"
  }
  enabled_log {
    category = "TriggerRuns"
  }
  enabled_log {
    category = "ActivityRuns"
  }

  # Métricas generales
  enabled_metric {
    category = "AllMetrics"
  }
}

# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# databricks.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------
# Daatabricks Workspace
# ------------------------------------------------------------------------------------------------

# 1. Create Databricks Workspace
resource "azurerm_databricks_workspace" "db_workspace" {
  name                = "db-workspace-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
  managed_resource_group_name = "rg-databricks-${var.project_name}"

  custom_parameters {
    no_public_ip       = true
    virtual_network_id = var.vnet_id
    private_subnet_name = var.private_subnet_name
    public_subnet_name  = var.public_subnet_name
    
    public_subnet_network_security_group_association_id  = var.public_nsg_assoc_id
    private_subnet_network_security_group_association_id = var.private_nsg_assoc_id
  }
}


# ------------------------------------------------------------------------------------------------
# Specific provider for Databricks
# ------------------------------------------------------------------------------------------------

  # 2. Definimos el Provider de forma dinámica
  provider "databricks" {
  alias = "workspace"
  
  
  host                        = try(azurerm_databricks_workspace.db_workspace.workspace_url, "")
  azure_workspace_resource_id = try(azurerm_databricks_workspace.db_workspace.id, "")
  
  auth_type = "azure-cli"
}

  # 3. Consultas al API (mantenemos la versión de Spark para la compatibilidad)
  data "databricks_spark_version" "latest_lts" {
    provider          = databricks.workspace
    long_term_support = true
    depends_on = [azurerm_databricks_workspace.db_workspace]
  }

  # 4. Creación del Clúster (Serverless Configuration)
  # resource "databricks_cluster" "serverless_cluster" {
  #  provider = databricks.workspace  # <--- ESTA ES LA CLAVE
    
  #  cluster_name            = "mi-cluster-prod"
  #  spark_version           = data.databricks_spark_version.latest_lts.id
  #  node_type_id            = "Standard_DS3_v2" 
  #  autotermination_minutes = 20
    
  #  autoscale {
  #    min_workers = 1
  #    max_workers = 2
  # depends_on = [azurerm_databricks_workspace.db_workspace]
  #}
#}

data "azuread_service_principal" "databricks_sp" {
  display_name = "AzureDatabricks" # Este es el nombre estándar del SP de Databricks en Azure
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

# 3. External Locations (Usando variables dinámicas)
resource "databricks_external_location" "uc_ext_loc_silver" {
  provider        = databricks.workspace
  name            = "ext-loc-${var.project_name}-silver"
  url             = var.storage_account_silver_url
  credential_name = databricks_storage_credential.uc_credential.id
  lifecycle {
    prevent_destroy = false
  }
}

resource "databricks_external_location" "uc_ext_loc_gold" {
  provider        = databricks.workspace
  name            = "ext-loc-${var.project_name}-gold"
  url             = var.storage_account_gold_url
  credential_name = databricks_storage_credential.uc_credential.id
  lifecycle {
    prevent_destroy = false
  }
}

# 4. Catalog
resource "databricks_catalog" "mongo_migration" {
  provider = databricks.workspace
  name     = "mongo_migration"
  storage_root = var.storage_account_silver_url
  comment  = "Catalog central para migración MongoDB"
  lifecycle {
    prevent_destroy = false
  }
}

# 5. Schemas (Apuntando a las ubicaciones externas)
resource "databricks_schema" "silver" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.mongo_migration.name
  name         = "silver"
  storage_root = var.storage_account_silver_url
  comment      = "Capa Silver"

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [databricks_external_location.uc_ext_loc_silver]
}

resource "databricks_schema" "gold" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.mongo_migration.name
  name         = "gold"
  storage_root = var.storage_account_gold_url
  comment      = "Capa Gold"

  lifecycle {
    prevent_destroy = false
  }
  
  depends_on = [databricks_external_location.uc_ext_loc_silver,
                databricks_external_location.uc_ext_loc_gold]
}

# ------------------------------------------------------------------------------------------------
# Configuration and path for the Notebooks 
# ------------------------------------------------------------------------------------------------

# 5. Creación del Notebook
resource "databricks_notebook" "migracion_silver" {
  provider = databricks.workspace
  
  # Esta es la ruta donde se verá el notebook dentro de tu Workspace de Databricks
  path     = "/Mongo-transformation/mongo-silver"
  
  
  language = "PYTHON"
  
  # Esta es la ruta a tu archivo local en tu máquina/repo
  source   = "${path.module}/notebooks/mongo-silver.py"
  
  depends_on = [azurerm_databricks_workspace.db_workspace]
}



# ------------------------------------------------------------------------------------------------
# Monitoring Databricks
# ------------------------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "db_diagnostics" {
  name                       = "diag-databricks-to-law"
  target_resource_id         = azurerm_databricks_workspace.db_workspace.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Usamos las categorías validadas por el comando CLI
  enabled_log {
    category = "clusters"
  }
  enabled_log {
    category = "jobs"
  }
  enabled_log {
    category = "notebook"
  }
  enabled_log {
    category = "workspace"
  }
  enabled_log {
    category = "unityCatalog"
  }
}