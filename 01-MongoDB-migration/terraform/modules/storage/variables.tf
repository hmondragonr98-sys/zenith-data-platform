variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }
variable "environment"         { type = string }

variable "replication"         { type = string}

variable "containers" {
  type        = list(string)
  description = "Lista de nombres de los contenedores para el Data Lake"
  default     = ["bronze", "silver", "gold", "control"]
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace para logs de Storage"
}

variable "adf_principal_id" {
  description = "El Principal ID de la Managed Identity del ADF"
  type        = string
}

variable "mongo_collections" {
  description = "Lista de colecciones de MongoDB a migrar (usada para inicializar el watermark)"
  type        = list(string)
}
