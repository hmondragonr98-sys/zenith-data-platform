variable "location" {
  type        = string
  description = "La región de Azure donde se desplegará el workspace"
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos para el workspace"
}

variable "resource_group_id" {
  type        = string
  description = "ID completo del grupo de recursos para el presupuesto"
}