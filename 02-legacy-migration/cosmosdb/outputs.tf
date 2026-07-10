

output "cosmos_db_endpoint" {
  value = azurerm_cosmosdb_account.mongodb.endpoint
}

data "azurerm_cosmosdb_account" "mongodb_read" {
  name                = azurerm_cosmosdb_account.mongodb.name
  resource_group_name = var.resource_group_name
}


output "cosmos_db_account_id" {
  value = azurerm_cosmosdb_account.mongodb.id
}