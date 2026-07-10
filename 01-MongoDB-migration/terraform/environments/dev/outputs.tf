# terraform/outputs.tf

output "resource_group_name" {
  description = "Nombre del único RG del entorno"
  value       = module.resource-groups.name
}