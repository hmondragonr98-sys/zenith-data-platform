# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# cosmosdb
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------


resource "azurerm_cosmosdb_account" "mongodb" {
  name                = "${var.project_name}-cosmos-01"
  location            = var.location
  mongo_server_version = "6.0"
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"
  
  capabilities {
    name = "EnableServerless"
  }


  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [
      capabilities # Esto evita que Terraform fuerce reemplazos por metadatos inyectados por la API
    ]
  }
}

resource "azurerm_cosmosdb_mongo_database" "db" {
  name                = "migration-db"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.mongodb.name

}

resource "azurerm_monitor_diagnostic_setting" "cosmos_diagnostics" {
  name                       = "diag-cosmos-to-law"
  target_resource_id         = azurerm_cosmosdb_account.mongodb.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Logs de auditoría y rendimiento
  enabled_log {
    category = "DataPlaneRequests"
  }
  enabled_log {
    category = "QueryRuntimeStatistics"
  }
  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_metric {
    category = "Requests"
  }
}