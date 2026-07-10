variable "resource_group_name"   { type = string }
variable "location"              { type = string }
variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "vnet_address_space"    { type = list(string) }
variable "subnet_endpoint_prefix" { type = list(string) }
variable "subnet_db_public_prefix" { type = list(string) }
variable "subnet_db_private_prefix" { type = list(string) }