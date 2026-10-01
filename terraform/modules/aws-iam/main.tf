# APEX-OS IAM/PAM — AWS IAM Module
# Manages IAM users, groups, roles, policies, and MFA enforcement

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── IAM Users ──────────────────────────────────────────────────────────────
resource "aws_iam_user" "users" {
  for_each = var.users

  name          = each.key
  path          = each.value.path
  force_destroy = each.value.force_destroy
  tags          = merge(var.common_tags, each.value.tags)
}

resource "aws_iam_user_login_profile" "login_profiles" {
  for_each = {
    for k, v in var.users : k => v
    if v.create_login_profile
  }

  user                    = aws_iam_user.users[each.key].name
  password_length         = var.password_length
  password_reset_required = true
  pgp_key                 = var.pgp_key
}

resource "aws_iam_user_group_membership" "memberships" {
  for_each = {
    for pair in setproduct(keys(var.users), var.group_names) : "${pair[0]}->${pair[1]}" => {
      user  = pair[0]
      group = pair[1]
    }
    if contains(var.users[pair[0]].groups, pair[1])
  }

  user   = aws_iam_user.users[each.value.user].name
  groups = [each.value.group]
}

# ── IAM Groups ─────────────────────────────────────────────────────────────
resource "aws_iam_group" "groups" {
  for_each = var.groups

  name = each.key
  path = each.value.path
}

resource "aws_iam_group_policy_attachment" "group_policy_attachments" {
  for_each = {
    for pair in setproduct(keys(var.groups), var.policy_arns) : "${pair[0]}->${pair[1]}" => {
      group = pair[0]
      arn   = pair[1]
    }
    if contains(var.groups[pair[0]].policy_arns, pair[1])
  }

  group      = aws_iam_group.groups[each.value.group].name
  policy_arn = each.value.arn
}

# ── IAM Roles ──────────────────────────────────────────────────────────────
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name                 = each.key
  path                 = each.value.path
  assume_role_policy   = each.value.assume_role_policy
  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary
  tags                 = merge(var.common_tags, each.value.tags)
}

resource "aws_iam_role_policy_attachment" "role_policy_attachments" {
  for_each = {
    for pair in setproduct(keys(var.roles), var.policy_arns) : "${pair[0]}->${pair[1]}" => {
      role = pair[0]
      arn  = pair[1]
    }
    if contains(var.roles[pair[0]].policy_arns, pair[1])
  }

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy" "inline_policies" {
  for_each = {
    for k, v in var.roles : k => v
    if v.inline_policy != null
  }

  name   = "${each.key}-inline-policy"
  role   = aws_iam_role.roles[each.key].name
  policy = each.value.inline_policy
}

# ── IAM Policies ───────────────────────────────────────────────────────────
resource "aws_iam_policy" "policies" {
  for_each = var.policies

  name        = each.key
  path        = each.value.path
  description = each.value.description
  policy      = each.value.policy
  tags        = merge(var.common_tags, each.value.tags)
}

# ── MFA Enforcement ────────────────────────────────────────────────────────
resource "aws_iam_group_policy" "mfa_enforcement" {
  for_each = var.enforce_mfa ? toset(var.group_names) : []

  name  = "${each.value}-mfa-enforcement"
  group = aws_iam_group.groups[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowManageOwnVirtualMFADevice"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:ListVirtualMFADevices",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice"
        ]
        Resource = [
          "arn:aws:iam::*:mfa/$${aws:username}",
          "arn:aws:iam::*:user/$${aws:username}"
        ]
      },
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

# ── Access Keys ────────────────────────────────────────────────────────────
resource "aws_iam_access_key" "access_keys" {
  for_each = {
    for k, v in var.users : k => v
    if v.create_access_key
  }

  user    = aws_iam_user.users[each.key].name
  pgp_key = var.pgp_key
}

# ── Account Password Policy ────────────────────────────────────────────────
resource "aws_iam_account_password_policy" "password_policy" {
  count = var.configure_password_policy ? 1 : 0

  minimum_password_length        = var.password_length
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}

# ── Service Control Policies (SCPs) ────────────────────────────────────────
resource "aws_organizations_policy" "scps" {
  for_each = var.service_control_policies

  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.content
  tags        = merge(var.common_tags, each.value.tags)
}
