variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }
variable "environment"         { type = string }

variable "storage_account_id"           { type = string } # Recibido desde el módulo storage
variable "storage_account_name"         { type = string } # Recibido desde el módulo storage
variable "storage_account_bronze_url"   { type = string }
variable "storage_account_silver_url"   { type = string }
variable "storage_account_gold_url"     { type = string }
variable "storage_account_control_url"  { type = string }

# Agrega las variables específicas de red si Databricks las requiere
variable "vnet_id"              { type = string }
variable "private_subnet_name"  { type = string }
variable "public_subnet_name"   { type = string }
variable "public_nsg_assoc_id"  { type = string }
variable "private_nsg_assoc_id" { type = string }


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

variable "enable_databricks_cluster" {
  description = "Si es true, crea un cluster de cómputo dedicado. False = solo Serverless (SQL Warehouse)."
  type        = bool
  default     = false
}

variable "databricks_node_type_id" {
  description = "Tipo de nodo para el cluster"
  type        = string
}

variable "databricks_min_workers" {
  type    = number
  default = 1
}

variable "databricks_max_workers" {
  type    = number
  default = 1
}

variable "databricks_autotermination_minutes" {
  type    = number
  default = 20
}