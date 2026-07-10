# modules/network/outputs.tf
output "vnet_id"                { value = azurerm_virtual_network.vnet.id }
output "db_private_subnet_name" { value = azurerm_subnet.snet_db_private.name }
output "db_public_subnet_name"  { value = azurerm_subnet.snet_db_public.name }
output "public_nsg_assoc_id"    { value = azurerm_subnet_network_security_group_association.public.id }
output "private_nsg_assoc_id"   { value = azurerm_subnet_network_security_group_association.private.id }

output "snet_endpoints_id" {
  description = "ID de la subred para Private Endpoints"
  value       = azurerm_subnet.snet_endpoints.id
}