# ------------------------------------------------------------------------------------------------
# private-endpoints.tf
# ------------------------------------------------------------------------------------------------

resource "azurerm_private_endpoint" "pe" {
  for_each            = var.endpoints
  name                = "pe-${var.project_name}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  timeouts {
    create = "12m"
    update = "12m"
  }

  private_service_connection {
    name                           = "psc-${each.key}"
    private_connection_resource_id = each.value.resource_id
    is_manual_connection           = false
    subresource_names              = each.value.subresource_names
  }

  private_dns_zone_group {
    name                 = "dns-group-${each.key}"
    private_dns_zone_ids = [each.value.dns_zone_id]
  }
}