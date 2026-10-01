# APEX-OS IAM/PAM — Azure IAM Module Outputs

output "user_ids" {
  description = "Object IDs of created Azure AD users"
  value       = [for k, v in azuread_user.users : v.id]
}

output "user_principal_names" {
  description = "Principal names of created Azure AD users"
  value       = [for k, v in azuread_user.users : v.user_principal_name]
}

output "group_ids" {
  description = "Object IDs of created Azure AD groups"
  value       = [for k, v in azuread_group.groups : v.id]
}

output "custom_role_ids" {
  description = "IDs of custom RBAC role definitions"
  value       = [for k, v in azurerm_role_definition.custom_roles : v.id]
}

output "role_assignment_ids" {
  description = "IDs of RBAC role assignments"
  value       = [for k, v in azurerm_role_assignment.role_assignments : v.id]
}

output "conditional_access_policy_ids" {
  description = "IDs of conditional access policies"
  value       = [for k, v in azuread_conditional_access_policy.conditional_access : v.id]
}
