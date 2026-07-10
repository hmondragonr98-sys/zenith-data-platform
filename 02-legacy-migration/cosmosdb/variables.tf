variable "project_name" {
  description = "Nombre del proyecto para el prefijo de recursos"
  type        = string
}

variable "environment" {
  description = "Entorno (prod, dev, etc.)"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos inyectado desde la raíz"
  type        = string
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace para logs de Cosmos DB"
}