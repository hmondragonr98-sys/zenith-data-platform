# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# databricks.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------
# Daatabricks Workspace
# ------------------------------------------------------------------------------------------------

# 1. Create Databricks Workspace
resource "azurerm_databricks_workspace" "db_workspace" {
  name                = "db-workspace-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
  managed_resource_group_name = "rg-databricks-${var.project_name}"

  custom_parameters {
    no_public_ip       = true
    virtual_network_id = var.vnet_id
    private_subnet_name = var.private_subnet_name
    public_subnet_name  = var.public_subnet_name
    
    public_subnet_network_security_group_association_id  = var.public_nsg_assoc_id
    private_subnet_network_security_group_association_id = var.private_nsg_assoc_id
  }
}


# ------------------------------------------------------------------------------------------------
# Specific provider for Databricks
# ------------------------------------------------------------------------------------------------

  # 2. Definimos el Provider de forma dinámica
  provider "databricks" {
  alias = "workspace"
  
  host                        = try(azurerm_databricks_workspace.db_workspace.workspace_url, "")
  azure_workspace_resource_id = try(azurerm_databricks_workspace.db_workspace.id, "")
  
  auth_type = "azure-cli"
}


data "databricks_current_user" "me" {
  provider = databricks.workspace

  depends_on = [azurerm_databricks_workspace.db_workspace]
}

data "azuread_service_principal" "databricks_sp" {
  display_name = "AzureDatabricks"
}



# 3. Consultas al API (mantenemos la versión de Spark para la compatibilidad)
data "databricks_spark_version" "latest_lts" {
  provider          = databricks.workspace
  long_term_support = true
  depends_on = [azurerm_databricks_workspace.db_workspace]
}


# ------------------------------------------------------------------------------------------------
# Databricks Cluster
# ------------------------------------------------------------------------------------------------

resource "databricks_cluster" "shared_cluster" {
  count    = var.enable_databricks_cluster ? 1 : 0
  provider = databricks.workspace

  cluster_name            = "cluster-${var.project_name}-${var.environment}"
  spark_version            = data.databricks_spark_version.latest_lts.id
  node_type_id             = var.databricks_node_type_id
  autotermination_minutes = var.databricks_autotermination_minutes
  data_security_mode      = "SINGLE_USER"

  single_user_name = data.databricks_current_user.me.user_name

  autoscale {
    min_workers = var.databricks_min_workers
    max_workers = var.databricks_max_workers
  }

  depends_on = [azurerm_databricks_workspace.db_workspace]
}



# ------------------------------------------------------------------------------------------------
# Configuration and path for the Notebooks 
# ------------------------------------------------------------------------------------------------

# 1. Asegurar el directorio base de dominios
resource "databricks_directory" "domains_root" {
  provider = databricks.workspace
  path     = "/domains"
  depends_on = [azurerm_databricks_workspace.db_workspace]
}

resource "databricks_directory" "domain_folders" {
  provider = databricks.workspace
  for_each = toset(["Logistics", "Comercial", "Catalogs"])
  
  path       = "/domains/${each.value}"
  depends_on = [databricks_directory.domains_root]
}

# 2. Creación de los notebooks utilizando tu misma estructura limpia
resource "databricks_notebook" "notebooks" {
  provider = databricks.workspace
  
  for_each = fileset("${path.module}/notebooks", "**/*.py")

  path     = "/domains/${trimsuffix(each.value, ".py")}"
  language = "PYTHON"
  source   = "${path.module}/notebooks/${each.value}"

  depends_on = [databricks_directory.domain_folders]
}



# ------------------------------------------------------------------------------------------------
# Monitoring Databricks
# ------------------------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "db_diagnostics" {
  name                       = "diag-databricks-to-law"
  target_resource_id         = azurerm_databricks_workspace.db_workspace.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Usamos las categorías validadas por el comando CLI
  enabled_log {
    category = "clusters"
  }
  enabled_log {
    category = "jobs"
  }
  enabled_log {
    category = "notebook"
  }
  enabled_log {
    category = "workspace"
  }
  enabled_log {
    category = "unityCatalog"
  }
}