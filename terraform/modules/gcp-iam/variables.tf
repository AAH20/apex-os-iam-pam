# APEX-OS IAM/PAM — GCP IAM Module Variables

variable "service_accounts" {
  description = "Map of GCP service accounts to create"
  type = map(object({
    display_name = string
    description  = optional(string, "Managed by APEX-OS IAM/PAM")
    project      = string
    create_key   = optional(bool, false)
  }))
  default = {}
}

variable "custom_roles" {
  description = "Map of GCP custom IAM roles"
  type = map(object({
    title       = string
    description = optional(string, "Managed by APEX-OS IAM/PAM")
    permissions = list(string)
    stage       = optional(string, "GA")
    project     = string
  }))
  default = {}
}

variable "project_bindings" {
  description = "Map of project-level IAM bindings"
  type = map(object({
    project              = string
    role                 = string
    member               = string
    condition_title      = optional(string)
    condition_description = optional(string)
    condition_expression = optional(string)
  }))
  default = {}
}

variable "project_role_bindings" {
  description = "Map of project-level IAM role bindings (multiple members)"
  type = map(object({
    project              = string
    role                 = string
    members              = list(string)
    condition_title      = optional(string)
    condition_description = optional(string)
    condition_expression = optional(string)
  }))
  default = {}
}

variable "org_bindings" {
  description = "Map of organization-level IAM bindings"
  type = map(object({
    org_id               = string
    role                 = string
    member               = string
    condition_title      = optional(string)
    condition_description = optional(string)
    condition_expression = optional(string)
  }))
  default = {}
}

variable "org_role_bindings" {
  description = "Map of organization-level IAM role bindings"
  type = map(object({
    org_id               = string
    role                 = string
    members              = list(string)
    condition_title      = optional(string)
    condition_description = optional(string)
    condition_expression = optional(string)
  }))
  default = {}
}

variable "folder_bindings" {
  description = "Map of folder-level IAM bindings"
  type = map(object({
    folder               = string
    role                 = string
    member               = string
    condition_title      = optional(string)
    condition_description = optional(string)
    condition_expression = optional(string)
  }))
  default = {}
}

variable "service_account_bindings" {
  description = "Map of service account IAM bindings"
  type = map(object({
    service_account_id = string
    role               = string
    member             = string
  }))
  default = {}
}

variable "audit_configs" {
  description = "Map of IAM audit configurations"
  type = map(object({
    project          = string
    service          = string
    log_type         = string
    exempted_members = optional(list(string), [])
  }))
  default = {}
}

variable "essential_contacts" {
  description = "Map of essential contacts"
  type = map(object({
    parent                              = string
    email                               = string
    language_tag                        = optional(string, "en")
    notification_category_subscriptions = list(string)
  }))
  default = {}
}
