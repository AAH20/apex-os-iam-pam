# APEX-OS IAM/PAM — Monitoring Module
# Manages CloudWatch, Azure Monitor, and GCP Monitoring resources for IAM/PAM observability

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# AWS CloudWatch Monitoring
# ═══════════════════════════════════════════════════════════════════════════

# ── CloudWatch Log Groups ──────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = var.aws_log_groups

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
  tags              = merge(var.common_tags, each.value.tags)
}

# ── CloudWatch Metric Alarms ───────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "metric_alarms" {
  for_each = var.aws_metric_alarms

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions
  dimensions          = each.value.dimensions
  tags                = merge(var.common_tags, each.value.tags)
}

# ── CloudWatch Dashboards ──────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "dashboards" {
  for_each = var.aws_dashboards

  dashboard_name = each.value.dashboard_name
  dashboard_body = each.value.dashboard_body
}

# ── CloudWatch Event Rules (Security Events) ──────────────────────────────
resource "aws_cloudwatch_event_rule" "event_rules" {
  for_each = var.aws_event_rules

  name        = each.value.name
  description = each.value.description
  event_pattern = each.value.event_pattern
  tags        = merge(var.common_tags, each.value.tags)
}

resource "aws_cloudwatch_event_target" "event_targets" {
  for_each = {
    for pair in setproduct(keys(var.aws_event_rules), var.aws_event_target_arns) : "${pair[0]}->${pair[1]}" => {
      rule = pair[0]
      arn  = pair[1]
    }
    if contains(var.aws_event_rules[pair[0]].target_arns, pair[1])
  }

  rule      = aws_cloudwatch_event_rule.event_rules[each.value.rule].name
  target_id = "${each.value.rule}-target"
  arn       = each.value.arn
}

# ── AWS Security Hub ──────────────────────────────────────────────────────
resource "aws_securityhub_account" "security_hub" {
  count = var.enable_aws_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "standards" {
  for_each = var.enable_aws_security_hub ? toset(var.security_hub_standards) : []

  standards_arn = each.value
  depends_on    = [aws_securityhub_account.security_hub]
}

# ── AWS GuardDuty ──────────────────────────────────────────────────────────
resource "aws_guardduty_detector" "guardduty" {
  count = var.enable_aws_guardduty ? 1 : 0

  enable = true
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        enable = true
      }
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# Azure Monitor
# ═══════════════════════════════════════════════════════════════════════════

# ── Azure Log Analytics Workspace ─────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "workspaces" {
  for_each = var.azure_log_workspaces

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku
  retention_in_days   = each.value.retention_in_days
  tags                = merge(var.common_tags, each.value.tags)
}

# ── Azure Monitor Action Groups ────────────────────────────────────────────
resource "azurerm_monitor_action_group" "action_groups" {
  for_each = var.azure_action_groups

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  short_name          = each.value.short_name

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }
}

# ── Azure Monitor Metric Alerts ────────────────────────────────────────────
resource "azurerm_monitor_metric_alert" "metric_alerts" {
  for_each = var.azure_metric_alerts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = each.value.action_group_id
  }

  tags = merge(var.common_tags, each.value.tags)
}

# ── Azure Monitor Activity Log Alerts ──────────────────────────────────────
resource "azurerm_monitor_activity_log_alert" "activity_alerts" {
  for_each = var.azure_activity_alerts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description

  criteria {
    category       = each.value.category
    operation_name = each.value.operation_name
    resource_type = each.value.resource_type
  }

  action {
    action_group_id = each.value.action_group_id
  }

  tags = merge(var.common_tags, each.value.tags)
}

# ═══════════════════════════════════════════════════════════════════════════
# GCP Monitoring
# ═══════════════════════════════════════════════════════════════════════════

# ── GCP Monitoring Alert Policies ─────────────────────────────────────────
resource "google_monitoring_alert_policy" "alert_policies" {
  for_each = var.gcp_alert_policies

  display_name = each.value.display_name
  project      = each.value.project
  combiner     = each.value.combiner

  conditions {
    display_name = each.value.condition_display_name

    condition_threshold {
      filter          = each.value.filter
      duration        = each.value.duration
      comparison      = each.value.comparison
      threshold_value = each.value.threshold_value
      aggregations {
        alignment_period     = each.value.alignment_period
        per_series_aligner   = each.value.per_series_aligner
      }
    }
  }

  notification_channels = each.value.notification_channels
  enabled               = each.value.enabled
}

# ── GCP Monitoring Notification Channels ──────────────────────────────────
resource "google_monitoring_notification_channel" "notification_channels" {
  for_each = var.gcp_notification_channels

  display_name = each.value.display_name
  project      = each.value.project
  type         = each.value.type
  labels       = each.value.labels
  user_labels  = each.value.user_labels
}

# ── GCP Monitoring Dashboards ─────────────────────────────────────────────
resource "google_monitoring_dashboard" "dashboards" {
  for_each = var.gcp_dashboards

  project      = each.value.project
  dashboard_json = each.value.dashboard_json
}

# ── GCP Monitoring Groups ─────────────────────────────────────────────────
resource "google_monitoring_group" "groups" {
  for_each = var.gcp_monitoring_groups

  display_name = each.value.display_name
  project      = each.value.project
  filter       = each.value.filter
}
