variable "module_list" {
  description = "Lista de servicios para los cuales se crearán RGs y recursos"
  type        = list(string)
  default     = ["storage", "network", "data-services", "key-vault", "observability"]
}

variable "project_name" {
  description = "Nombre del proyecto, usado para prefijos"
  type        = string
  default     = "mongo"
}

variable "environment" {
  description = "Entorno del despliegue (prod, dev, uat)"
  type        = string
  default     = "test"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus"
}

variable "mongo_collections" {
  description = "Lista de colecciones de MongoDB a migrar"
  type        = list(string)
  default     = ["pedidos", "productos", "usuarios", "suscripciones"]
}