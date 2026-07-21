# ------------------------------------------------------------------------------------------------
# Action Group para Alertas de Monitoreo
# ------------------------------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "email_alert" {
  name                = "ag-mongo-migration-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "mongo-alerts"

  email_receiver {
    name                    = "Héctor Mondragón Reyes"
    email_address           = "hmondragon.r98@gmail.com"
    use_common_alert_schema = true
  }
}

# ------------------------------------------------------------------------------------------------
# Log Analytics
# ------------------------------------------------------------------------------------------------

# 1. Workspace de Logs
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "law-mongo-migration-${var.environment}-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "budget-mongo-migration"
  resource_group_id = var.resource_group_id
  amount            = var.monthly_budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = "${formatdate("YYYY-MM", timestamp())}-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = var.budget_alert_threshold
    operator       = "GreaterThan"
    contact_emails = ["hmondragon.r98@gmail.com"]
  }

  lifecycle {
    ignore_changes = all
  }
}



# ------------------------------------------------------------------------------------------------
# Alert Rules: Log Analytics for system failures (ADF)
# ------------------------------------------------------------------------------------------------

resource "azurerm_monitor_scheduled_query_rules_alert" "system_failure_alert" {
  name                = "alert-system-pipeline-failures"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Id found on this module
  data_source_id      = azurerm_log_analytics_workspace.logs.id

  # Frequency and window time
  frequency           = 5
  time_window         = 5

  # KQL querie for failure detection
  query = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.DATAFACTORY" and Category == "PipelineRuns"
    | where status_s == "Failed"
    | project TimeGenerated, Resource, pipelineName_s, error_s
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group           = [azurerm_monitor_action_group.email_alert.id]
    custom_webhook_payload = "{}"
  }
}