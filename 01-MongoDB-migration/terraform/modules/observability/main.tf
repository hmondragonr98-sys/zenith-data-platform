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