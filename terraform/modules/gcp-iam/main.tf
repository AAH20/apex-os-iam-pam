# APEX-OS IAM/PAM — GCP IAM Module
# Manages GCP service accounts, IAM policies, and custom roles

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ── GCP Service Accounts ───────────────────────────────────────────────────
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = each.value.project
}

resource "google_service_account_key" "service_account_keys" {
  for_each = {
    for k, v in var.service_accounts : k => v
    if v.create_key
  }

  service_account_id = google_service_account.service_accounts[each.key].name
  key_algorithm      = "KEY_ALG_RSA_2048"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# ── GCP IAM Custom Roles ───────────────────────────────────────────────────
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.custom_roles

  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
  project     = each.value.project
}

# ── GCP IAM Policy Bindings (Project Level) ────────────────────────────────
resource "google_project_iam_member" "project_bindings" {
  for_each = var.project_bindings

  project = each.value.project
  role    = each.value.role
  member  = each.value.member
  condition {
    title       = each.value.condition_title
    description = each.value.condition_description
    expression  = each.value.condition_expression
  }
}

resource "google_project_iam_binding" "project_role_bindings" {
  for_each = var.project_role_bindings

  project = each.value.project
  role    = each.value.role
  members = each.value.members
  condition {
    title       = each.value.condition_title
    description = each.value.condition_description
    expression  = each.value.condition_expression
  }
}

# ── GCP IAM Policy Bindings (Organization Level) ──────────────────────────
resource "google_organization_iam_member" "org_bindings" {
  for_each = var.org_bindings

  org_id  = each.value.org_id
  role    = each.value.role
  member  = each.value.member
  condition {
    title       = each.value.condition_title
    description = each.value.condition_description
    expression  = each.value.condition_expression
  }
}

resource "google_organization_iam_binding" "org_role_bindings" {
  for_each = var.org_role_bindings

  org_id  = each.value.org_id
  role    = each.value.role
  members = each.value.members
  condition {
    title       = each.value.condition_title
    description = each.value.condition_description
    expression  = each.value.condition_expression
  }
}

# ── GCP IAM Policy Bindings (Folder Level) ────────────────────────────────
resource "google_folder_iam_member" "folder_bindings" {
  for_each = var.folder_bindings

  folder  = each.value.folder
  role    = each.value.role
  member  = each.value.member
  condition {
    title       = each.value.condition_title
    description = each.value.condition_description
    expression  = each.value.condition_expression
  }
}

# ── GCP Service Account IAM Bindings ──────────────────────────────────────
resource "google_service_account_iam_member" "sa_bindings" {
  for_each = var.service_account_bindings

  service_account_id = each.value.service_account_id
  role               = each.value.role
  member             = each.value.member
}

# ── GCP IAM Audit Config ──────────────────────────────────────────────────
resource "google_project_iam_audit_config" "audit_configs" {
  for_each = var.audit_configs

  project = each.value.project
  service = each.value.service

  audit_log_config {
    log_type         = each.value.log_type
    exempted_members = each.value.exempted_members
  }
}

# ── GCP Essential Contacts ────────────────────────────────────────────────
resource "google_essential_contacts_contact" "contacts" {
  for_each = var.essential_contacts

  parent                        = each.value.parent
  email                         = each.value.email
  language_tag                  = each.value.language_tag
  notification_category_subscriptions = each.value.notification_category_subscriptions
}
