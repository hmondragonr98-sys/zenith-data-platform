variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "storage_account_id"  { type = string } # Recibido desde el módulo storage
variable "storage_account_name"  { type = string } # Recibido desde el módulo storage

variable "databricks_workspace_id" { type = string }

variable "cluster_id" { type = string }


variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace para enviar logs"
}

variable "key_vault_id" {
  type        = string
  description = "El ID del recurso de Key Vault al cual conectarse"
}

variable "key_vault_uri" {
  description = "La URI del Key Vault para que el ADF pueda leer los secretos"
  type        = string
}

variable "key_vault_name" {
  description = "El nombre del Key Vault"
  type        = string
}