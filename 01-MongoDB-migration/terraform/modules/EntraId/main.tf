# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# EntraID.tf
# ------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------------
# Dinamic Groups
# ------------------------------------------------------------------------------------------------

# --- 1. GRUPOS GLOBALES DE PLATAFORMA (Únicos) ---
resource "azuread_group" "platform_admins" {
  display_name     = "grp-${var.environment}-platform-admins"
  security_enabled = true
}

resource "azuread_group" "platform_network" {
  display_name     = "grp-${var.environment}-platform-network"
  security_enabled = true
}

# --- 2. GRUPOS POR DOMINIO (Data Mesh: Solo Data Engineers y Analytics) ---
resource "azuread_group" "domain_data_engineers" {
  for_each         = toset(var.domains)
  display_name     = "grp-${var.environment}-${each.value}-data-engineers"
  security_enabled = true
}

resource "azuread_group" "domain_analytics" {
  for_each         = toset(var.domains)
  display_name     = "grp-${var.environment}-${each.value}-analytics"
  security_enabled = true
}




# ------------------------------------------------------------------------------------------------
# Users
# ------------------------------------------------------------------------------------------------

locals {
  users_data = csvdecode(file("${path.module}/users.csv"))
}

# Crear usuarios dinámicamente desde el CSV
resource "azuread_user" "csv_users" {
  for_each = { for u in local.users_data : u.userPrincipalName => u }

  user_principal_name   = each.value.userPrincipalName
  display_name          = each.value.displayName
  mail_nickname         = each.value.mailNickname
  job_title             = each.value.jobTitle
  usage_location        = each.value.usageLocation
  account_enabled       = each.value.accountEnabled

  # Campos para la contraseña y el cambio obligatorio
  password              = each.value.password
  force_password_change = true
}