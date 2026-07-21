output "platform_admin_group_id" {
  value = azuread_group.platform_admins.id
}

output "platform_network_group_id" {
  value = azuread_group.platform_network.id
}

output "data_engineer_group_ids" {
  value = { for k, g in azuread_group.domain_data_engineers : k => g.id }
}

output "analytics_group_ids" {
  value = { for k, g in azuread_group.domain_analytics : k => g.id }
}