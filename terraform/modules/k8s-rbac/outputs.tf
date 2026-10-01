# APEX-OS IAM/PAM — Kubernetes RBAC Module Outputs

output "namespace_names" {
  description = "Names of created namespaces"
  value       = [for k, v in kubernetes_namespace.namespaces : v.metadata[0].name]
}

output "role_names" {
  description = "Names of created Roles"
  value       = [for k, v in kubernetes_role.roles : v.metadata[0].name]
}

output "cluster_role_names" {
  description = "Names of created ClusterRoles"
  value       = [for k, v in kubernetes_cluster_role.cluster_roles : v.metadata[0].name]
}

output "role_binding_names" {
  description = "Names of created RoleBindings"
  value       = [for k, v in kubernetes_role_binding.role_bindings : v.metadata[0].name]
}

output "cluster_role_binding_names" {
  description = "Names of created ClusterRoleBindings"
  value       = [for k, v in kubernetes_cluster_role_binding.cluster_role_bindings : v.metadata[0].name]
}

output "service_account_names" {
  description = "Names of created ServiceAccounts"
  value       = [for k, v in kubernetes_service_account.service_accounts : v.metadata[0].name]
}

output "network_policy_names" {
  description = "Names of created NetworkPolicies"
  value       = [for k, v in kubernetes_network_policy.network_policies : v.metadata[0].name]
}
