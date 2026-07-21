#-----------------------------------------------------------------------------------
# DNS
#-----------------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "dns_zones" {
  for_each = toset([
    "privatelink.dfs.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azuredatabricks.net"
  ])
  name                = each.value
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_links" {
  for_each              = azurerm_private_dns_zone.dns_zones
  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones[each.key].name
  virtual_network_id    = var.vnet_id
}