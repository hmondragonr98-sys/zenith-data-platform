variable "resource_group_name" {
  description = "Nombre del grupo de recursos donde se crearán las zonas DNS"
  type        = string
}

variable "vnet_id" {
  description = "ID de la red virtual para crear el enlace"
  type        = string
}