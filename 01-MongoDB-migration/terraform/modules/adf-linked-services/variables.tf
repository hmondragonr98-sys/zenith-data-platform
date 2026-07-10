
variable "key_vault_id" { type = string }
variable "storage_account_id" { type = string }
variable "storage_account_name" {type = string}
variable "storage_account_primary_dfs_endpoint" { type = string }
variable "adf_id" { type = string }
variable "integration_runtime_name" {
  type = string
}
variable "adf_principal_id" {
  description = "Principal ID de la Managed Identity del ADF, usado para asignar roles RBAC"
  type        = string
}

variable "mongo_collections" {
  type        = list(string)
  description = "Lista de nombres de las colecciones de MongoDB a migrar"
  default     = ["usuarios", "pedidos", "productos", "suscripciones"] # Ejemplo
} 


variable "integration_runtime_name_local" {
  type = string
}



variable "enable_mongo_linked_service" {
  type    = bool
  default = true
}
