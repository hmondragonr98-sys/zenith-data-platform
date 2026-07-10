output "storage_account_id" {
  value = azurerm_storage_account.datalake.id
}

output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "primary_dfs_endpoint" {
  value = azurerm_storage_account.datalake.primary_dfs_endpoint
}

output "storage_account_silver_url" {
  value = "abfss://${azurerm_storage_container.medallion["silver"].name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net/"
}

output "storage_account_gold_url" {
  value = "abfss://${azurerm_storage_container.medallion["gold"].name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net/"
}