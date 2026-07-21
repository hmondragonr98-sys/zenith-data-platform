# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# Root main.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

module "resource-groups" {
  source   = "../../modules/resource-groups"
  
  project_name = var.project_name
  environment  = var.environment
  location     = var.location
}

# ------------------------------------------------------------------------------------------------
# Storage.tf
# ------------------------------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  # Aquí ocurre la conexión:
  # Estamos extrayendo el nombre del RG creado dinámicamente para "storage"
  resource_group_name = module.resource-groups.name
  location            = var.location
  
  project_name        = var.project_name
  environment         = var.environment
  replication         = var.replication

  mongo_collections   = var.mongo_collections

  adf_principal_id    = module.adf.adf_principal_id

  log_analytics_workspace_id = module.observability.law_id
}

# ------------------------------------------------------------------------------------------------
# adf.tf
# ------------------------------------------------------------------------------------------------

module "adf" {
  source              = "../../modules/adf"
  
  resource_group_name = module.resource-groups.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  
  # Conectamos con el módulo de red

  key_vault_id   = module.key-vault.key_vault_id
  key_vault_uri  = module.key-vault.vault_uri
  key_vault_name = module.key-vault.vault_name

  log_analytics_workspace_id = module.observability.law_id

  storage_account_id  = module.storage.storage_account_id
  storage_account_name = module.storage.storage_account_name
}

# ------------------------------------------------------------------------------------------------
# data-services.tf
# ------------------------------------------------------------------------------------------------

module "data-services" {
  source              = "../../modules/data-services"
  
  resource_group_name = module.resource-groups.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  
  # Conectamos con el módulo de red
  vnet_id              = module.network.vnet_id
  private_subnet_name  = module.network.db_private_subnet_name
  public_subnet_name   = module.network.db_public_subnet_name
  public_nsg_assoc_id  = module.network.public_nsg_assoc_id
  private_nsg_assoc_id = module.network.private_nsg_assoc_id

  key_vault_id   = module.key-vault.key_vault_id
  key_vault_uri  = module.key-vault.vault_uri
  key_vault_name = module.key-vault.vault_name

  log_analytics_workspace_id = module.observability.law_id

  storage_account_id  = module.storage.storage_account_id
  storage_account_name = module.storage.storage_account_name
  storage_account_silver_url = module.storage.storage_account_silver_url
  storage_account_gold_url = module.storage.storage_account_gold_url
}

# ------------------------------------------------------------------------------------------------
# vault.tf
# ------------------------------------------------------------------------------------------------

module "key-vault" {
  source              = "../../modules/key-vault"
  resource_group_name = module.resource-groups.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  sku_name            = var.sku_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  admin_object_id     = data.azurerm_client_config.current.object_id
  
  
  service_principal_ids = [
    module.adf.adf_principal_id,
    module.data-services.databricks_sp_object_id
  ]

  log_analytics_workspace_id = module.observability.law_id
}

# ------------------------------------------------------------------------------------------------
# network.tf
# ------------------------------------------------------------------------------------------------

module "network" {
  source              = "../../modules/network"
  
  # Información básica
  resource_group_name = module.resource-groups.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  
  # Rangos de IP (puedes definirlos como variables en la raíz)
  vnet_address_space       = var.vnet_address_space
  subnet_endpoint_prefix   = var.subnet_endpoint_prefix
  subnet_db_public_prefix  = var.subnet_db_public_prefix
  subnet_db_private_prefix = var.subnet_db_private_prefix
}


# ------------------------------------------------------------------------------------------------
# private-endpoints.tf
# ------------------------------------------------------------------------------------------------

module "private-endpoints" {
  source              = "../../modules/private-endpoints"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.resource-groups.name
  subnet_id           = module.network.snet_endpoints_id


  endpoints = {
    storage = {
      resource_id       = module.storage.storage_account_id
      subresource_names = ["blob"]
      dns_zone_id       = module.dns.dns_zone_ids["privatelink.dfs.core.windows.net"]
    }
    keyvault = {
      resource_id       = module.key-vault.key_vault_id
      subresource_names = ["vault"]
      dns_zone_id       = module.dns.dns_zone_ids["privatelink.vaultcore.azure.net"]
    }
  }
  depends_on = [module.storage, module.key-vault]
}

# ------------------------------------------------------------------------------------------------
# dns.tf
# ------------------------------------------------------------------------------------------------

module "dns" {
  source              = "../../modules/dns"
  resource_group_name = module.resource-groups.name
  vnet_id             = module.network.vnet_id
}

# ------------------------------------------------------------------------------------------------
# obsevability.tf
# ------------------------------------------------------------------------------------------------

module "observability" {
  source              = "../../modules/observability"
  
  location              = var.location
  monthly_budget_amount = var.monthly_budget_amount
  environment           = var.environment
  budget_alert_threshold = var.budget_alert_threshold

  # Asumiendo que tienes un módulo de resource-groups
  resource_group_name = module.resource-groups.name
  resource_group_id   = module.resource-groups.id
}


# ------------------------------------------------------------------------------------------------
# adf-linked-services.tf
# ------------------------------------------------------------------------------------------------


module "adf-linked-services" {
  source             = "../../modules/adf-linked-services"

  # Pasando los IDs reales obtenidos de otros módulos
  adf_id             = module.adf.adf_id
  adf_principal_id   = module.adf.adf_principal_id
  key_vault_id       = module.key-vault.key_vault_id
  storage_account_id = module.storage.storage_account_id
  storage_account_name = module.storage.storage_account_name

  storage_account_primary_dfs_endpoint = module.storage.primary_dfs_endpoint

  integration_runtime_name = module.adf.ir_managed_vnet_name

  integration_runtime_name_local = module.adf.shir_name

  depends_on = [
    module.key-vault,
    module.storage
  ]
}