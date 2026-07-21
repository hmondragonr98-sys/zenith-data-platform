enable_databricks_cluster          = true
databricks_node_type_id            = "Standard_D4s_v3"
databricks_min_workers             = 1
databricks_max_workers             = 1
databricks_autotermination_minutes = 30

enable_mongo_linked_service = true

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

database = "mongo-migrate"

mongo_collections = ["orders", "order_items", "payments", "customers", "reviews", "products", "sellers", "category_name", "geolocation"]

domains = ["logistics", "commercial", "catalog"]