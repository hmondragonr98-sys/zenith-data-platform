# modules/keyvault/outputs.tf

output "key_vault_id" {
  description = "El ID de recurso del Key Vault (usado para políticas de acceso)"
  value       = azurerm_key_vault.vault.id
}

output "vault_uri" {
  description = "La URI del Key Vault (usada por las aplicaciones para leer secretos)"
  value       = azurerm_key_vault.vault.vault_uri
}

output "vault_name" {
  description = "El nombre del Key Vault"
  value       = azurerm_key_vault.vault.name
}