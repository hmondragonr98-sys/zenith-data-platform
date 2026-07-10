output "private_endpoint_ids" {
  description = "Mapa de los IDs de todos los Private Endpoints creados"
  value       = { for k, pe in azurerm_private_endpoint.pe : k => pe.id }
}

output "private_endpoint_ips" {
  description = "Mapa de las direcciones IP privadas asignadas a cada endpoint"
  value       = { for k, pe in azurerm_private_endpoint.pe : k => pe.private_service_connection[0].private_ip_address }
}