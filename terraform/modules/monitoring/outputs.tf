# APEX-OS IAM/PAM — Monitoring Module Outputs

# ── AWS Outputs ────────────────────────────────────────────────────────────
output "aws_log_group_arns" {
  description = "ARNs of CloudWatch log groups"
  value       = [for k, v in aws_cloudwatch_log_group.log_groups : v.arn]
}

output "aws_metric_alarm_arns" {
  description = "ARNs of CloudWatch metric alarms"
  value       = [for k, v in aws_cloudwatch_metric_alarm.metric_alarms : v.arn]
}

output "aws_dashboard_names" {
  description = "Names of CloudWatch dashboards"
  value       = [for k, v in aws_cloudwatch_dashboard.dashboards : v.dashboard_name]
}

output "aws_event_rule_arns" {
  description = "ARNs of CloudWatch event rules"
  value       = [for k, v in aws_cloudwatch_event_rule.event_rules : v.arn]
}

# ── Azure Outputs ──────────────────────────────────────────────────────────
output "azure_log_workspace_ids" {
  description = "IDs of Log Analytics workspaces"
  value       = [for k, v in azurerm_log_analytics_workspace.workspaces : v.id]
}

output "azure_action_group_ids" {
  description = "IDs of action groups"
  value       = [for k, v in azurerm_monitor_action_group.action_groups : v.id]
}

output "azure_metric_alert_ids" {
  description = "IDs of metric alerts"
  value       = [for k, v in azurerm_monitor_metric_alert.metric_alerts : v.id]
}

# ── GCP Outputs ────────────────────────────────────────────────────────────
output "gcp_alert_policy_ids" {
  description = "IDs of GCP alert policies"
  value       = [for k, v in google_monitoring_alert_policy.alert_policies : v.id]
}

output "gcp_notification_channel_ids" {
  description = "IDs of GCP notification channels"
  value       = [for k, v in google_monitoring_notification_channel.notification_channels : v.id]
}

output "gcp_dashboard_ids" {
  description = "IDs of GCP dashboards"
  value       = [for k, v in google_monitoring_dashboard.dashboards : v.id]
}
