# APEX-OS IAM/PAM — Monitoring Module Variables

# ── AWS Variables ──────────────────────────────────────────────────────────
variable "aws_log_groups" {
  description = "Map of CloudWatch log groups"
  type = map(object({
    name              = string
    retention_in_days = optional(number, 90)
    kms_key_id        = optional(string)
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "aws_metric_alarms" {
  description = "Map of CloudWatch metric alarms"
  type = map(object({
    alarm_name                = string
    comparison_operator       = string
    evaluation_periods        = number
    metric_name               = string
    namespace                 = string
    period                    = number
    statistic                 = string
    threshold                 = number
    alarm_description         = optional(string)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    dimensions                = optional(map(string), {})
    tags                      = optional(map(string), {})
  }))
  default = {}
}

variable "aws_dashboards" {
  description = "Map of CloudWatch dashboards"
  type = map(object({
    dashboard_name = string
    dashboard_body = string
  }))
  default = {}
}

variable "aws_event_rules" {
  description = "Map of CloudWatch event rules"
  type = map(object({
    name          = string
    description   = optional(string)
    event_pattern = string
    target_arns   = optional(list(string), [])
    tags          = optional(map(string), {})
  }))
  default = {}
}

variable "aws_event_target_arns" {
  description = "List of event target ARNs"
  type        = list(string)
  default     = []
}

variable "enable_aws_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "security_hub_standards" {
  description = "List of Security Hub standards to enable"
  type        = list(string)
  default = [
    "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    "arn:aws:securityhub:::ruleset/pci-dss/v/3.2.1"
  ]
}

variable "enable_aws_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

# ── Azure Variables ────────────────────────────────────────────────────────
variable "azure_log_workspaces" {
  description = "Map of Azure Log Analytics workspaces"
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    sku                 = optional(string, "PerGB2018")
    retention_in_days   = optional(number, 90)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "azure_action_groups" {
  description = "Map of Azure Monitor action groups"
  type = map(object({
    name                = string
    resource_group_name = string
    short_name          = string
    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), [])
  }))
  default = {}
}

variable "azure_metric_alerts" {
  description = "Map of Azure Monitor metric alerts"
  type = map(object({
    name                = string
    resource_group_name = string
    scopes              = list(string)
    description         = optional(string)
    severity            = optional(number, 2)
    frequency           = optional(string, "PT5M")
    window_size         = optional(string, "PT5M")
    metric_namespace    = string
    metric_name         = string
    aggregation         = string
    operator            = string
    threshold           = number
    action_group_id     = string
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "azure_activity_alerts" {
  description = "Map of Azure Monitor activity log alerts"
  type = map(object({
    name                = string
    resource_group_name = string
    scopes              = list(string)
    description         = optional(string)
    category            = string
    operation_name      = string
    resource_type       = string
    action_group_id     = string
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ── GCP Variables ──────────────────────────────────────────────────────────
variable "gcp_alert_policies" {
  description = "Map of GCP monitoring alert policies"
  type = map(object({
    display_name            = string
    project                 = string
    combiner                = optional(string, "OR")
    condition_display_name  = string
    filter                  = string
    duration                = optional(string, "60s")
    comparison              = string
    threshold_value         = number
    alignment_period        = optional(string, "60s")
    per_series_aligner      = optional(string, "ALIGN_MEAN")
    notification_channels  = list(string)
    enabled                 = optional(bool, true)
  }))
  default = {}
}

variable "gcp_notification_channels" {
  description = "Map of GCP notification channels"
  type = map(object({
    display_name = string
    project      = string
    type         = string
    labels       = map(string)
    user_labels  = optional(map(string), {})
  }))
  default = {}
}

variable "gcp_dashboards" {
  description = "Map of GCP monitoring dashboards"
  type = map(object({
    project        = string
    dashboard_json = string
  }))
  default = {}
}

variable "gcp_monitoring_groups" {
  description = "Map of GCP monitoring groups"
  type = map(object({
    display_name = string
    project      = string
    filter       = string
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "APEX-OS-IAM-PAM"
  }
}
