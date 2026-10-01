# APEX-OS IAM/PAM — GCP IAM Module Outputs

output "service_account_ids" {
  description = "IDs of created service accounts"
  value       = [for k, v in google_service_account.service_accounts : v.id]
}

output "service_account_emails" {
  description = "Emails of created service accounts"
  value       = [for k, v in google_service_account.service_accounts : v.email]
}

output "service_account_keys" {
  description = "Private keys of service accounts (sensitive)"
  value       = [for k, v in google_service_account_key.service_account_keys : v.private_key]
  sensitive   = true
}

output "custom_role_ids" {
  description = "IDs of custom IAM roles"
  value       = [for k, v in google_project_iam_custom_role.custom_roles : v.id]
}

output "project_binding_ids" {
  description = "IDs of project-level IAM bindings"
  value       = [for k, v in google_project_iam_member.project_bindings : v.id]
}

output "org_binding_ids" {
  description = "IDs of organization-level IAM bindings"
  value       = [for k, v in google_organization_iam_member.org_bindings : v.id]
}
