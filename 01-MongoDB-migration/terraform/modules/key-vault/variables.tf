variable "resource_group_name"   { type = string }
variable "location"              { type = string }
variable "project_name"          { type = string }
variable "tenant_id"             { type = string }
variable "admin_object_id"       { type = string }
variable "service_principal_ids" { type = list(string) } # Aquí recibes los IDs de ADF y Databricks

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace"
}