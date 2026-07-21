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

variable "mongo_collections" {
  description = "Lista de colecciones de MongoDB a migrar"
  type        = list(string)
  default     = ["pedidos", "productos", "usuarios", "suscripciones"]
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
