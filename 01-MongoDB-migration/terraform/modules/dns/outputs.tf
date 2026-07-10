output "dns_zone_ids" {
  description = "Mapa de los IDs de las zonas DNS privadas para ser usado por otros módulos"
  value       = { for k, zone in azurerm_private_dns_zone.dns_zones : zone.name => zone.id }
}