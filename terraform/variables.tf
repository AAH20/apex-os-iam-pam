# APEX-OS IAM/PAM — Root Module Variables

# ═══════════════════════════════════════════════════════════════════════════
# Global Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = ""
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "k8s_host" {
  description = "Kubernetes API server host"
  type        = string
  default     = ""
}

variable "k8s_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  type        = string
  default     = ""
}

variable "k8s_token" {
  description = "Kubernetes authentication token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "APEX-OS"
    Component = "IAM-PAM"
    ManagedBy = "Terraform"
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# AWS IAM Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "aws_users" {
  description = "Map of AWS IAM users"
  type        = any
  default     = {}
}

variable "aws_groups" {
  description = "Map of AWS IAM groups"
  type        = any
  default     = {}
}

variable "aws_roles" {
  description = "Map of AWS IAM roles"
  type        = any
  default     = {}
}

variable "aws_policies" {
  description = "Map of AWS IAM policies"
  type        = any
  default     = {}
}

variable "aws_policy_arns" {
  description = "List of AWS managed policy ARNs"
  type        = list(string)
  default     = []
}

variable "aws_group_names" {
  description = "List of AWS group names"
  type        = list(string)
  default     = []
}

variable "aws_enforce_mfa" {
  description = "Enforce MFA for AWS"
  type        = bool
  default     = true
}

variable "aws_password_length" {
  description = "AWS minimum password length"
  type        = number
  default     = 16
}

variable "aws_pgp_key" {
  description = "PGP key for AWS credential encryption"
  type        = string
  default     = ""
}

variable "aws_configure_password_policy" {
  description = "Configure AWS account password policy"
  type        = bool
  default     = true
}

variable "aws_service_control_policies" {
  description = "Map of AWS SCPs"
  type        = any
  default     = {}
}

# ═══════════════════════════════════════════════════════════════════════════
# Azure IAM Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "azure_users" {
  description = "Map of Azure AD users"
  type        = any
  default     = {}
}

variable "azure_groups" {
  description = "Map of Azure AD groups"
  type        = any
  default     = {}
}

variable "azure_user_principal_names" {
  description = "List of Azure user principal names"
  type        = list(string)
  default     = []
}

variable "azure_custom_roles" {
  description = "Map of Azure custom roles"
  type        = any
  default     = {}
}

variable "azure_role_assignments" {
  description = "Map of Azure role assignments"
  type        = any
  default     = {}
}

variable "azure_conditional_access_policies" {
  description = "Map of Azure conditional access policies"
  type        = any
  default     = {}
}

variable "azure_pim_active_assignments" {
  description = "Map of Azure PIM active assignments"
  type        = any
  default     = {}
}

variable "azure_pim_eligible_assignments" {
  description = "Map of Azure PIM eligible assignments"
  type        = any
  default     = {}
}

variable "azure_key_vault_access_policies" {
  description = "Map of Azure Key Vault access policies"
  type        = any
  default     = {}
}

# ═══════════════════════════════════════════════════════════════════════════
# GCP IAM Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "gcp_service_accounts" {
  description = "Map of GCP service accounts"
  type        = any
  default     = {}
}

variable "gcp_custom_roles" {
  description = "Map of GCP custom roles"
  type        = any
  default     = {}
}

variable "gcp_project_bindings" {
  description = "Map of GCP project bindings"
  type        = any
  default     = {}
}

variable "gcp_project_role_bindings" {
  description = "Map of GCP project role bindings"
  type        = any
  default     = {}
}

variable "gcp_org_bindings" {
  description = "Map of GCP org bindings"
  type        = any
  default     = {}
}

variable "gcp_org_role_bindings" {
  description = "Map of GCP org role bindings"
  type        = any
  default     = {}
}

variable "gcp_folder_bindings" {
  description = "Map of GCP folder bindings"
  type        = any
  default     = {}
}

variable "gcp_service_account_bindings" {
  description = "Map of GCP service account bindings"
  type        = any
  default     = {}
}

variable "gcp_audit_configs" {
  description = "Map of GCP audit configs"
  type        = any
  default     = {}
}

variable "gcp_essential_contacts" {
  description = "Map of GCP essential contacts"
  type        = any
  default     = {}
}

# ═══════════════════════════════════════════════════════════════════════════
# Kubernetes RBAC Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "k8s_namespaces" {
  description = "Map of K8s namespaces"
  type        = any
  default     = {}
}

variable "k8s_roles" {
  description = "Map of K8s roles"
  type        = any
  default     = {}
}

variable "k8s_cluster_roles" {
  description = "Map of K8s cluster roles"
  type        = any
  default     = {}
}

variable "k8s_role_bindings" {
  description = "Map of K8s role bindings"
  type        = any
  default     = {}
}

variable "k8s_cluster_role_bindings" {
  description = "Map of K8s cluster role bindings"
  type        = any
  default     = {}
}

variable "k8s_service_accounts" {
  description = "Map of K8s service accounts"
  type        = any
  default     = {}
}

variable "k8s_pod_security_policies" {
  description = "Map of K8s pod security policies"
  type        = any
  default     = {}
}

variable "k8s_network_policies" {
  description = "Map of K8s network policies"
  type        = any
  default     = {}
}

# ═══════════════════════════════════════════════════════════════════════════
# Monitoring Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "monitoring_aws_log_groups" {
  description = "Map of CloudWatch log groups"
  type        = any
  default     = {}
}

variable "monitoring_aws_metric_alarms" {
  description = "Map of CloudWatch metric alarms"
  type        = any
  default     = {}
}

variable "monitoring_aws_dashboards" {
  description = "Map of CloudWatch dashboards"
  type        = any
  default     = {}
}

variable "monitoring_aws_event_rules" {
  description = "Map of CloudWatch event rules"
  type        = any
  default     = {}
}

variable "monitoring_aws_event_target_arns" {
  description = "List of CloudWatch event target ARNs"
  type        = list(string)
  default     = []
}

variable "monitoring_enable_aws_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "monitoring_security_hub_standards" {
  description = "List of Security Hub standards"
  type        = list(string)
  default     = []
}

variable "monitoring_enable_aws_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

variable "monitoring_azure_log_workspaces" {
  description = "Map of Azure Log Analytics workspaces"
  type        = any
  default     = {}
}

variable "monitoring_azure_action_groups" {
  description = "Map of Azure action groups"
  type        = any
  default     = {}
}

variable "monitoring_azure_metric_alerts" {
  description = "Map of Azure metric alerts"
  type        = any
  default     = {}
}

variable "monitoring_azure_activity_alerts" {
  description = "Map of Azure activity alerts"
  type        = any
  default     = {}
}

variable "monitoring_gcp_alert_policies" {
  description = "Map of GCP alert policies"
  type        = any
  default     = {}
}

variable "monitoring_gcp_notification_channels" {
  description = "Map of GCP notification channels"
  type        = any
  default     = {}
}

variable "monitoring_gcp_dashboards" {
  description = "Map of GCP dashboards"
  type        = any
  default     = {}
}

variable "monitoring_gcp_monitoring_groups" {
  description = "Map of GCP monitoring groups"
  type        = any
  default     = {}
}

# ═══════════════════════════════════════════════════════════════════════════
# Security Groups Variables
# ═══════════════════════════════════════════════════════════════════════════
variable "sg_aws_security_groups" {
  description = "Map of AWS security groups"
  type        = any
  default     = {}
}

variable "sg_aws_standalone_rules" {
  description = "Map of AWS standalone rules"
  type        = any
  default     = {}
}

variable "sg_azure_nsgs" {
  description = "Map of Azure NSGs"
  type        = any
  default     = {}
}

variable "sg_azure_subnet_nsg_associations" {
  description = "Map of Azure subnet-NSG associations"
  type        = any
  default     = {}
}

variable "sg_azure_nic_nsg_associations" {
  description = "Map of Azure NIC-NSG associations"
  type        = any
  default     = {}
}

variable "sg_gcp_firewall_rules" {
  description = "Map of GCP firewall rules"
  type        = any
  default     = {}
}

variable "sg_gcp_firewall_policies" {
  description = "Map of GCP firewall policies"
  type        = any
  default     = {}
}

variable "sg_gcp_firewall_policy_rules" {
  description = "Map of GCP firewall policy rules"
  type        = any
  default     = {}
}

variable "sg_gcp_firewall_policy_associations" {
  description = "Map of GCP firewall policy associations"
  type        = any
  default     = {}
}
