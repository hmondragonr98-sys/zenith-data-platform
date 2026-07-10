output "law_id" {
  description = "ID del Log Analytics Workspace para configurar diagnósticos"
  value       = azurerm_log_analytics_workspace.logs.id
}
