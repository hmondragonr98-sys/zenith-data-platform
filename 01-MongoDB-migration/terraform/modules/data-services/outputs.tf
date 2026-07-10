output "databricks_sp_object_id" {
  description = "ID del Service Principal de Databricks"
  # Si aún no tienes esta data source, la añadiremos abajo
  value       = data.azuread_service_principal.databricks_sp.object_id
}