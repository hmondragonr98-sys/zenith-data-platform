# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# vault.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------

resource "azurerm_key_vault" "vault" {
  name                     = "kv-${var.project_name}-01"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  tenant_id                = var.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false 
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# Política para TU usuario
resource "azurerm_key_vault_access_policy" "admin_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = var.tenant_id
  object_id    = var.admin_object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
}

# 1. Política para el Data Factory
resource "azurerm_key_vault_access_policy" "adf_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = var.tenant_id
  object_id    = var.service_principal_ids[0] # El primero de la lista

  secret_permissions = ["Get", "List"]
}

# 2. Política para Databricks
resource "azurerm_key_vault_access_policy" "databricks_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = var.tenant_id
  object_id    = var.service_principal_ids[1] # El segundo de la lista

  secret_permissions = ["Get", "List"]
}

# ------------------------------------------------------------------------------------------------
# obervability
# ------------------------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "kv_diagnostics" {
  name                       = "diag-kv-to-law"
  target_resource_id         = azurerm_key_vault.vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Logs de auditoría y acceso
  enabled_log {
    category = "AuditEvent"
  }
  
  # Métricas
  enabled_metric {
    category = "AllMetrics"
  }
}