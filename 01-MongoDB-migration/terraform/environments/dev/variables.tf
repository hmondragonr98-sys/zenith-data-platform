variable "project_name" {
  description = "Nombre del proyecto, usado para prefijos"
  type        = string
  default     = "mongo"
}

variable "environment" {
  description = "Entorno del despliegue (prod, dev, uat)"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "database" {
  type    = string
  description = "MongoDB/Json format"
}

variable "mongo_collections" {
  description = "Lista de colecciones de MongoDB a migrar"
  type        = list(string)
}

variable "replication" {
  description = "Level of storage replication"
  type =  string
}

variable "sku_name" { type = string }

variable "vnet_address_space"       { type = list(string) }
variable "subnet_endpoint_prefix"   { type = list(string) }
variable "subnet_db_public_prefix"  { type = list(string) }
variable "subnet_db_private_prefix" { type = list(string) }

variable "monthly_budget_amount" {
  description = "Monto mensual del budget de alerta, en USD"
  type        = number
}
variable "budget_alert_threshold" {
  type    = number
}


variable "enable_databricks_cluster" { type = bool }

variable "enable_mongo_linked_service" { type = bool }



variable "databricks_node_type_id"            { type = string }
variable "databricks_min_workers"             { type = number }
variable "databricks_max_workers"             { type = number }
variable "databricks_autotermination_minutes" { type = number }


variable "domains" {
  type = list(string)
}