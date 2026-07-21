output "databricks_sp_object_id" {
  description = "ID del Service Principal de Databricks"
  value       = data.azuread_service_principal.databricks_sp.object_id
}

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.db_workspace.id
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.db_workspace.workspace_url
}

output "cluster_id" {
  description = "ID del clúster de Databricks compartido"
  value       = var.enable_databricks_cluster ? databricks_cluster.shared_cluster[0].id : null
}

