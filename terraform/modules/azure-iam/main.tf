# APEX-OS IAM/PAM — Azure IAM Module
# Manages Azure AD users, groups, roles, and RBAC assignments

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# ── Azure AD Users ─────────────────────────────────────────────────────────
resource "azuread_user" "users" {
  for_each = var.users

  user_principal_name = each.value.user_principal_name
  display_name        = each.value.display_name
  password            = each.value.password
  force_password_change = each.value.force_password_change
  account_enabled     = each.value.account_enabled
  mail_nickname       = each.value.mail_nickname
  job_title           = each.value.job_title
  department          = each.value.department
  usage_location      = each.value.usage_location
}

# ── Azure AD Groups ────────────────────────────────────────────────────────
resource "azuread_group" "groups" {
  for_each = var.groups

  display_name     = each.key
  security_enabled = each.value.security_enabled
  mail_enabled     = each.value.mail_enabled
  mail_nickname    = each.value.mail_nickname
  owners           = each.value.owners
  members          = each.value.members
}

resource "azuread_group_member" "group_members" {
  for_each = {
    for pair in setproduct(keys(var.groups), var.user_principal_names) : "${pair[0]}->${pair[1]}" => {
      group = pair[0]
      user  = pair[1]
    }
    if contains(var.groups[pair[0]].members, pair[1])
  }

  group_object_id  = azuread_group.groups[each.value.group].id
  member_object_id = azuread_user.users[each.value.user].id
}

# ── Azure RBAC Role Definitions ────────────────────────────────────────────
resource "azurerm_role_definition" "custom_roles" {
  for_each = var.custom_roles

  name        = each.key
  scope       = each.value.scope
  description = each.value.description

  permissions {
    actions          = each.value.actions
    not_actions      = each.value.not_actions
    data_actions     = each.value.data_actions
    not_data_actions = each.value.not_data_actions
  }

  assignable_scopes = each.value.assignable_scopes
}

# ── Azure RBAC Role Assignments ────────────────────────────────────────────
resource "azurerm_role_assignment" "role_assignments" {
  for_each = var.role_assignments

  name                = each.value.name
  scope               = each.value.scope
  role_definition_id  = each.value.role_definition_id
  principal_id        = each.value.principal_id
  description         = each.value.description
  skip_service_principal_aadcheck = each.value.skip_service_principal_aadcheck
}

# ── Azure AD Conditional Access Policies ───────────────────────────────────
resource "azuread_conditional_access_policy" "conditional_access" {
  for_each = var.conditional_access_policies

  display_name = each.key
  state        = each.value.state

  conditions {
    applications {
      included_applications = each.value.included_applications
      excluded_applications = each.value.excluded_applications
    }

    users {
      included_users = each.value.included_users
      excluded_users = each.value.excluded_users
      included_groups = each.value.included_groups
      excluded_groups = each.value.excluded_groups
    }

    platforms {
      included_platforms = each.value.included_platforms
      excluded_platforms = each.value.excluded_platforms
    }

    locations {
      included_locations = each.value.included_locations
      excluded_locations = each.value.excluded_locations
    }

    sign_in_risk_levels    = each.value.sign_in_risk_levels
    user_risk_levels       = each.value.user_risk_levels
  }

  grant_controls {
    operator          = each.value.grant_operator
    built_in_controls = each.value.built_in_controls
    custom_authentication_factors = each.value.custom_authentication_factors
    terms_of_use        = each.value.terms_of_use
  }

  session_controls {
    sign_in_frequency = each.value.sign_in_frequency
    sign_in_frequency_period = each.value.sign_in_frequency_period
    persistent_browser_mode  = each.value.persistent_browser_mode
    cloud_app_security_policy = each.value.cloud_app_security_policy
  }
}

# ── Azure AD PIM (Privileged Identity Management) ─────────────────────────
resource "azurerm_pim_active_role_assignment" "pim_active" {
  for_each = var.pim_active_assignments

  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.principal_id
  ticket_number      = each.value.ticket_number
  ticket_system      = each.value.ticket_system
  justification      = each.value.justification
  schedule {
    start_date_time = each.value.start_date_time
    expiration {
      end_date_time = each.value.end_date_time
    }
  }
}

resource "azurerm_pim_eligible_role_assignment" "pim_eligible" {
  for_each = var.pim_eligible_assignments

  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.principal_id
  ticket_number      = each.value.ticket_number
  ticket_system      = each.value.ticket_system
  justification      = each.value.justification
  schedule {
    start_date_time = each.value.start_date_time
    expiration {
      end_date_time = each.value.end_date_time
    }
  }
}

# ── Azure Key Vault Access Policies ────────────────────────────────────────
resource "azurerm_key_vault_access_policy" "kv_access_policies" {
  for_each = var.key_vault_access_policies

  key_vault_id = each.value.key_vault_id
  tenant_id    = each.value.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}
