variable "project_name" { type = string }
variable "location"     { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id"    { type = string }

variable "endpoints" {
  type = map(object({
    resource_id       = string
    subresource_names = list(string)
    dns_zone_id       = string
  }))
}
