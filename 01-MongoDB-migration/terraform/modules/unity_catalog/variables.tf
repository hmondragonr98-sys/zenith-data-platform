variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }

variable "storage_account_id"           { type = string } # Recibido desde el módulo storage
variable "storage_account_name"         { type = string } # Recibido desde el módulo storage
variable "storage_account_bronze_url"   { type = string }
variable "storage_account_silver_url"   { type = string }
variable "storage_account_gold_url"     { type = string }
variable "storage_account_control_url"  { type = string }

variable "databricks_workspace_url" { type = string }
variable "databricks_workspace_id" { type = string }