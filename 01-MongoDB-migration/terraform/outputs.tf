# terraform/outputs.tf

output "resource_group_names" {
  description = "Mapa de todos los RGs creados"
  # module.resource-groups es el nombre del bloque que definiste en main.tf
  value = { for key, m in module.resource-groups : key => m.name }
}