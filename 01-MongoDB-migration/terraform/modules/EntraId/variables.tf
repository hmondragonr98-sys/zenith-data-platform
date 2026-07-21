variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "environment"         { type = string }


variable "domains" {
  type        = list(string)
  description = "Lista de dominios de negocio (ej. logistics, commercial, catalog)"
}