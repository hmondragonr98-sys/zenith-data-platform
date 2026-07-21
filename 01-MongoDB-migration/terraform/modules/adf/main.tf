# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# adf.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------
# data Factory Workspace
# ------------------------------------------------------------------------------------------------

# 1. ADF
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
# Storage Role assigment
# ------------------------------------------------------------------------------------------------

resource "azurerm_role_assignment" "adf_storage_access" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
  
  depends_on = [azurerm_data_factory.adf]
}

resource "azurerm_role_assignment" "adf_to_databricks_workspace" {
  scope                = var.databricks_workspace_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id

  depends_on = [
    azurerm_data_factory.adf
  ]
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