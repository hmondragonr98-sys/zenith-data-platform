# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# storage account, blobs
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------

# 0. Data source para obtener la identidad de Databricks en el Tenant
# Esto permite localizar la identidad de forma segura e idempotente


data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}


data "azuread_service_principal" "databricks_sp" {
  display_name = "AzureDatabricks"
}

# 1. Definición del Storage Account
resource "azurerm_storage_account" "datalake" {
  name = "st${replace(var.project_name, "-", "")}01"
  resource_group_name      = var.resource_group_name 
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  shared_access_key_enabled = true 

  network_rules {
    default_action = "Deny"
    # El bypass permite que ADF acceda al Data Lake incluso con default_action "Deny"
    bypass         = ["AzureServices"] 
    ip_rules       = [chomp(data.http.my_ip.response_body)]
  }
}

# 2. Definición de los contenedores
resource "azurerm_storage_container" "medallion" {
  for_each           = toset(var.containers)
  name               = each.value
  storage_account_id = azurerm_storage_account.datalake.id

  depends_on = [azurerm_storage_account.datalake]
}

resource "azurerm_storage_blob" "watermark_initial" {
  name                   = "watermark.json"
  storage_account_name   = azurerm_storage_account.datalake.name
  storage_container_name = azurerm_storage_container.medallion["control"].name
  type                   = "Block"
  content_type           = "application/json"

  source_content = jsonencode({
    for coll in var.mongo_collections : coll => "2020-01-01T00:00:00Z"
  })

  lifecycle {
    ignore_changes = [source_content]
  }
}


# 3. Permiso para que Databricks acceda al Storage Account
resource "azurerm_role_assignment" "db_storage_access" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  
  # Usamos el Service Principal encontrado por el data source
  # Esto elimina el error de "Invalid index"
  principal_id         = data.azuread_service_principal.databricks_sp.object_id
  
  # Aseguramos que la asignación espere al Storage
  depends_on           = [azurerm_storage_account.datalake]
}



resource "azurerm_role_assignment" "adf_storage_access" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.adf_principal_id
  
  depends_on = [azurerm_storage_account.datalake]
}












resource "azurerm_monitor_diagnostic_setting" "storage_diagnostics" {
  name                       = "diag-storage-to-law"
  target_resource_id         = azurerm_storage_account.datalake.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # BORRA TODOS LOS enabled_log porque Azure confirmó que no existen para este recurso.
  
  # Agrega solo las métricas válidas que nos dio el CLI:
  enabled_metric {
    category = "Capacity"
  }
  enabled_metric {
    category = "Transaction"
  }
}