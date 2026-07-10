# modules/resource-groups/outputs.tf
output "name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  description = "La ubicación del recurso creado"
  value       = azurerm_resource_group.rg.location
}

output "id" {
  value = azurerm_resource_group.rg.id # Asegúrate de que el nombre del recurso sea el correcto
}