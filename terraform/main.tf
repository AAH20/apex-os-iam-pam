# APEX-OS IAM/PAM — Root Module
# Orchestrates all IAM/PAM modules across AWS, Azure, GCP, K8s, Monitoring, and Security Groups

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "apex-os-iam-pam-tfstate"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "apex-os-iam-pam-tfstate-lock"
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# AWS Provider
# ═══════════════════════════════════════════════════════════════════════════
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "APEX-OS"
      Component   = "IAM-PAM"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# Azure Providers
# ═══════════════════════════════════════════════════════════════════════════
provider "azuread" {
  tenant_id = var.azure_tenant_id
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# ═══════════════════════════════════════════════════════════════════════════
# GCP Provider
# ═══════════════════════════════════════════════════════════════════════════
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ═══════════════════════════════════════════════════════════════════════════
# Kubernetes Provider
# ═══════════════════════════════════════════════════════════════════════════
provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = var.k8s_cluster_ca_certificate
  token                  = var.k8s_token
}

# ═══════════════════════════════════════════════════════════════════════════
# Module: AWS IAM
# ═══════════════════════════════════════════════════════════════════════════
module "aws_iam" {
  source = "./modules/aws-iam"

  users                          = var.aws_users
  groups                         = var.aws_groups
  roles                          = var.aws_roles
  policies                       = var.aws_policies
  policy_arns                    = var.aws_policy_arns
  group_names                    = var.aws_group_names
  enforce_mfa                    = var.aws_enforce_mfa
  password_length                = var.aws_password_length
  pgp_key                        = var.aws_pgp_key
  configure_password_policy      = var.aws_configure_password_policy
  service_control_policies       = var.aws_service_control_policies
  common_tags                    = var.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════
# Module: Azure IAM
# ═══════════════════════════════════════════════════════════════════════════
module "azure_iam" {
  source = "./modules/azure-iam"

  users                          = var.azure_users
  groups                         = var.azure_groups
  user_principal_names           = var.azure_user_principal_names
  custom_roles                   = var.azure_custom_roles
  role_assignments               = var.azure_role_assignments
  conditional_access_policies    = var.azure_conditional_access_policies
  pim_active_assignments         = var.azure_pim_active_assignments
  pim_eligible_assignments       = var.azure_pim_eligible_assignments
  key_vault_access_policies      = var.azure_key_vault_access_policies
}

# ═══════════════════════════════════════════════════════════════════════════
# Module: GCP IAM
# ═══════════════════════════════════════════════════════════════════════════
module "gcp_iam" {
  source = "./modules/gcp-iam"

  service_accounts               = var.gcp_service_accounts
  custom_roles                   = var.gcp_custom_roles
  project_bindings               = var.gcp_project_bindings
  project_role_bindings          = var.gcp_project_role_bindings
  org_bindings                   = var.gcp_org_bindings
  org_role_bindings              = var.gcp_org_role_bindings
  folder_bindings                = var.gcp_folder_bindings
  service_account_bindings       = var.gcp_service_account_bindings
  audit_configs                  = var.gcp_audit_configs
  essential_contacts             = var.gcp_essential_contacts
}

# ═══════════════════════════════════════════════════════════════════════════
# Module: Kubernetes RBAC
# ═══════════════════════════════════════════════════════════════════════════
module "k8s_rbac" {
  source = "./modules/k8s-rbac"

  namespaces                     = var.k8s_namespaces
  roles                          = var.k8s_roles
  cluster_roles                  = var.k8s_cluster_roles
  role_bindings                  = var.k8s_role_bindings
  cluster_role_bindings          = var.k8s_cluster_role_bindings
  service_accounts               = var.k8s_service_accounts
  pod_security_policies          = var.k8s_pod_security_policies
  network_policies               = var.k8s_network_policies
  common_labels                  = var.common_labels
}

# ═══════════════════════════════════════════════════════════════════════════
# Module: Monitoring
# ═══════════════════════════════════════════════════════════════════════════
module "monitoring" {
  source = "./modules/monitoring"

  aws_log_groups                 = var.monitoring_aws_log_groups
  aws_metric_alarms              = var.monitoring_aws_metric_alarms
  aws_dashboards                 = var.monitoring_aws_dashboards
  aws_event_rules                = var.monitoring_aws_event_rules
  aws_event_target_arns          = var.monitoring_aws_event_target_arns
  enable_aws_security_hub        = var.monitoring_enable_aws_security_hub
  security_hub_standards         = var.monitoring_security_hub_standards
  enable_aws_guardduty           = var.monitoring_enable_aws_guardduty

  azure_log_workspaces           = var.monitoring_azure_log_workspaces
  azure_action_groups            = var.monitoring_azure_action_groups
  azure_metric_alerts            = var.monitoring_azure_metric_alerts
  azure_activity_alerts         = var.monitoring_azure_activity_alerts

  gcp_alert_policies             = var.monitoring_gcp_alert_policies
  gcp_notification_channels      = var.monitoring_gcp_notification_channels
  gcp_dashboards                 = var.monitoring_gcp_dashboards
  gcp_monitoring_groups          = var.monitoring_gcp_monitoring_groups

  common_tags                    = var.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════
# Module: Security Groups
# ═══════════════════════════════════════════════════════════════════════════
module "security_groups" {
  source = "./modules/security-groups"

  aws_security_groups            = var.sg_aws_security_groups
  aws_standalone_rules           = var.sg_aws_standalone_rules

  azure_nsgs                     = var.sg_azure_nsgs
  azure_subnet_nsg_associations  = var.sg_azure_subnet_nsg_associations
  azure_nic_nsg_associations     = var.sg_azure_nic_nsg_associations

  gcp_firewall_rules             = var.sg_gcp_firewall_rules
  gcp_firewall_policies          = var.sg_gcp_firewall_policies
  gcp_firewall_policy_rules      = var.sg_gcp_firewall_policy_rules
  gcp_firewall_policy_associations = var.sg_gcp_firewall_policy_associations

  common_tags                    = var.common_tags
}
