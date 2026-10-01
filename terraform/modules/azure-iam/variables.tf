# APEX-OS IAM/PAM — Azure IAM Module Variables

variable "users" {
  description = "Map of Azure AD users to create"
  type = map(object({
    user_principal_name   = string
    display_name          = string
    password              = string
    force_password_change = optional(bool, true)
    account_enabled       = optional(bool, true)
    mail_nickname         = optional(string)
    job_title             = optional(string)
    department            = optional(string)
    usage_location        = optional(string)
  }))
  default = {}
}

variable "groups" {
  description = "Map of Azure AD groups to create"
  type = map(object({
    security_enabled = optional(bool, true)
    mail_enabled     = optional(bool, false)
    mail_nickname    = optional(string)
    owners           = optional(list(string), [])
    members          = optional(list(string), [])
  }))
  default = {}
}

variable "user_principal_names" {
  description = "List of user principal names for membership resolution"
  type        = list(string)
  default     = []
}

variable "custom_roles" {
  description = "Map of custom RBAC role definitions"
  type = map(object({
    scope              = string
    description        = optional(string, "Managed by APEX-OS IAM/PAM")
    actions            = optional(list(string), [])
    not_actions        = optional(list(string), [])
    data_actions       = optional(list(string), [])
    not_data_actions   = optional(list(string), [])
    assignable_scopes  = list(string)
  }))
  default = {}
}

variable "role_assignments" {
  description = "Map of RBAC role assignments"
  type = map(object({
    name                = optional(string)
    scope               = string
    role_definition_id  = string
    principal_id        = string
    description         = optional(string)
    skip_service_principal_aadcheck = optional(bool, false)
  }))
  default = {}
}

variable "conditional_access_policies" {
  description = "Map of conditional access policies"
  type = map(object({
    state                    = string
    included_applications    = optional(list(string), [])
    excluded_applications    = optional(list(string), [])
    included_users           = optional(list(string), [])
    excluded_users           = optional(list(string), [])
    included_groups          = optional(list(string), [])
    excluded_groups          = optional(list(string), [])
    included_platforms       = optional(list(string), [])
    excluded_platforms       = optional(list(string), [])
    included_locations       = optional(list(string), [])
    excluded_locations       = optional(list(string), [])
    sign_in_risk_levels      = optional(list(string), [])
    user_risk_levels         = optional(list(string), [])
    grant_operator           = string
    built_in_controls        = list(string)
    custom_authentication_factors = optional(list(string), [])
    terms_of_use             = optional(list(string), [])
    sign_in_frequency        = optional(number)
    sign_in_frequency_period = optional(string)
    persistent_browser_mode  = optional(string)
    cloud_app_security_policy = optional(string)
  }))
  default = {}
}

variable "pim_active_assignments" {
  description = "Map of PIM active role assignments"
  type = map(object({
    scope              = string
    role_definition_id = string
    principal_id       = string
    ticket_number      = optional(string)
    ticket_system      = optional(string)
    justification      = optional(string)
    start_date_time    = string
    end_date_time      = string
  }))
  default = {}
}

variable "pim_eligible_assignments" {
  description = "Map of PIM eligible role assignments"
  type = map(object({
    scope              = string
    role_definition_id = string
    principal_id       = string
    ticket_number      = optional(string)
    ticket_system      = optional(string)
    justification      = optional(string)
    start_date_time    = string
    end_date_time      = string
  }))
  default = {}
}

variable "key_vault_access_policies" {
  description = "Map of Key Vault access policies"
  type = map(object({
    key_vault_id            = string
    tenant_id               = string
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = {}
}
