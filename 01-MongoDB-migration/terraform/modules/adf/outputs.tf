output "adf_principal_id" {
  description = "ID de la identidad del Data Factory"
  value       = azurerm_data_factory.adf.identity[0].principal_id
}

output "ir_managed_vnet_name" {
  description = "Nombre del IR con Managed VNet para usar en Linked Services"
  value       = azurerm_data_factory_integration_runtime_azure.ir_managed_vnet.name
}

output "shir_primary_key" {
  description = "Llave primaria para registrar el SHIR en tu laptop"
  value       = azurerm_data_factory_integration_runtime_self_hosted.shir.primary_authorization_key
  sensitive   = true
}

output "adf_id" {
  value = azurerm_data_factory.adf.id
}

output "shir_name" {
  description = "Llave primaria para registrar el SHIR en tu laptop"
  value       = azurerm_data_factory_integration_runtime_self_hosted.shir.name
  sensitive   = true
}