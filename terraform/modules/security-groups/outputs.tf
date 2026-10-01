# APEX-OS IAM/PAM — Security Groups Module Outputs

# ── AWS Outputs ────────────────────────────────────────────────────────────
output "aws_security_group_ids" {
  description = "IDs of AWS security groups"
  value       = [for k, v in aws_security_group.security_groups : v.id]
}

output "aws_security_group_arns" {
  description = "ARNs of AWS security groups"
  value       = [for k, v in aws_security_group.security_groups : v.arn]
}

output "aws_standalone_rule_ids" {
  description = "IDs of standalone security group rules"
  value       = [for k, v in aws_security_group_rule.standalone_rules : v.id]
}

# ── Azure Outputs ──────────────────────────────────────────────────────────
output "azure_nsg_ids" {
  description = "IDs of Azure NSGs"
  value       = [for k, v in azurerm_network_security_group.nsgs : v.id]
}

output "azure_subnet_nsg_association_ids" {
  description = "IDs of subnet-NSG associations"
  value       = [for k, v in azurerm_subnet_network_security_group_association.subnet_nsg_associations : v.id]
}

# ── GCP Outputs ────────────────────────────────────────────────────────────
output "gcp_firewall_rule_ids" {
  description = "IDs of GCP firewall rules"
  value       = [for k, v in google_compute_firewall.firewall_rules : v.id]
}

output "gcp_firewall_policy_ids" {
  description = "IDs of GCP firewall policies"
  value       = [for k, v in google_compute_firewall_policy.firewall_policies : v.id]
}

output "gcp_firewall_policy_rule_ids" {
  description = "IDs of GCP firewall policy rules"
  value       = [for k, v in google_compute_firewall_policy_rule.firewall_policy_rules : v.id]
}
