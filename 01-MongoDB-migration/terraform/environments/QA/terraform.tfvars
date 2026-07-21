enable_databricks_cluster = false

replication               = "LRS"

environment               = "dev"

location                  = "eastus"

sku_name                  = "standard"

vnet_address_space        = ["10.0.0.0/22"]
subnet_endpoint_prefix    = ["10.0.1.0/26"]
subnet_db_public_prefix   = ["10.0.2.0/26"]
subnet_db_private_prefix  = ["10.0.3.0/26"]

monthly_budget_amount     = 10
budget_alert_threshold    = 75


enable_databricks_cluster          = true
databricks_node_type_id            = "Standard_DS3_v2"   # ajustaremos cuando revisemos prod a fondo
databricks_min_workers             = 2
databricks_max_workers             = 4
databricks_autotermination_minutes = 30