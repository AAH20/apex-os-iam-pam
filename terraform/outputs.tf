# APEX-OS IAM/PAM — Root Module Outputs

# ═══════════════════════════════════════════════════════════════════════════
# AWS IAM Outputs
# ═══════════════════════════════════════════════════════════════════════════
output "aws_iam_user_names" {
  description = "Names of created AWS IAM users"
  value       = module.aws_iam.user_names
}

output "aws_iam_user_arns" {
  description = "ARNs of created AWS IAM users"
  value       = module.aws_iam.user_arns
}

output "aws_iam_group_names" {
  description = "Names of created AWS IAM groups"
  value       = module.aws_iam.group_names
}

output "aws_iam_role_names" {
  description = "Names of created AWS IAM roles"
  value       = module.aws_iam.role_names
}

output "aws_iam_role_arns" {
  description = "ARNs of created AWS IAM roles"
  value       = module.aws_iam.role_arns
}

output "aws_iam_policy_arns" {
  description = "ARNs of created AWS IAM policies"
  value       = module.aws_iam.policy_arns
}

# ═══════════════════════════════════════════════════════════════════════════
# Azure IAM Outputs
# ═══════════════════════════════════════════════════════════════════════════
output "azure_iam_user_ids" {
  description = "Object IDs of created Azure AD users"
  value       = module.azure_iam.user_ids
}

output "azure_iam_group_ids" {
  description = "Object IDs of created Azure AD groups"
  value       = module.azure_iam.group_ids
}

output "azure_iam_custom_role_ids" {
  description = "IDs of custom Azure RBAC roles"
  value       = module.azure_iam.custom_role_ids
}

output "azure_iam_role_assignment_ids" {
  description = "IDs of Azure role assignments"
  value       = module.azure_iam.role_assignment_ids
}

# ═══════════════════════════════════════════════════════════════════════════
# GCP IAM Outputs
# ═══════════════════════════════════════════════════════════════════════════
output "gcp_iam_service_account_ids" {
  description = "IDs of created GCP service accounts"
  value       = module.gcp_iam.service_account_ids
}

output "gcp_iam_service_account_emails" {
  description = "Emails of created GCP service accounts"
  value       = module.gcp_iam.service_account_emails
}

output "gcp_iam_custom_role_ids" {
  description = "IDs of custom GCP IAM roles"
  value       = module.gcp_iam.custom_role_ids
}

# ═══════════════════════════════════════════════════════════════════════════
# Kubernetes RBAC Outputs
# ═══════════════════════════════════════════════════════════════════════════
output "k8s_namespace_names" {
  description = "Names of created K8s namespaces"
  value       = module.k8s_rbac.namespace_names
}

output "k8s_role_names" {
  description = "Names of created K8s roles"
  value       = module.k8s_rbac.role_names
}

output "k8s_cluster_role_names" {
  description = "Names of created K8s cluster roles"
  value       = module.k8s_rbac.cluster_role_names
}

output "k8s_role_binding_names" {
  description = "Names of created K8s role bindings"
  value       = module.k8s_rbac.role_binding_names
}

output "k8s_cluster_role_binding_names" {
  description = "Names of created K8s cluster role bindings"
  value       = module.k8s_rbac.cluster_role_binding_names
}

# ═══════════════════════════════════════════════════════════════════════════
# Monitoring Outputs
# ═══════════════════════════════════════════════════════════════════════════
output "monitoring_aws_log_group_arns" {
  description = "ARNs of CloudWatch log groups"
  value       = module.monitoring.aws_log_group_arns
}

output "monitoring_aws_metric_alarm_arns" {
  description = "ARNs of CloudWatch metric alarms"
  value       = module.monitoring.aws_metric_alarm_arns
}

output "monitoring_azure_log_workspace_ids" {
  description = "IDs of Azure Log Analytics workspaces"
  value       = module.monitoring.azure_log_workspace_ids
}

output "monitoring_gcp_alert_policy_ids" {
  description = "IDs of GCP alert policies"
  value       = module.monitoring.gcp_alert_policy_ids
}

# ═══════════════════════════════════════════════════════════════════════════
# Security Groups Outputs
# ═══════════════════════════════════════════════════════════════════════════
output "sg_aws_security_group_ids" {
  description = "IDs of AWS security groups"
  value       = module.security_groups.aws_security_group_ids
}

output "sg_azure_nsg_ids" {
  description = "IDs of Azure NSGs"
  value       = module.security_groups.azure_nsg_ids
}

output "sg_gcp_firewall_rule_ids" {
  description = "IDs of GCP firewall rules"
  value       = module.security_groups.gcp_firewall_rule_ids
}
