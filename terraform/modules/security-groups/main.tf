# APEX-OS IAM/PAM — Security Groups Module
# Manages AWS Security Groups, Azure NSGs, and GCP Firewall Rules

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
# AWS Security Groups
# ═══════════════════════════════════════════════════════════════════════════

resource "aws_security_group" "security_groups" {
  for_each = var.aws_security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = each.value.vpc_id
  tags        = merge(var.common_tags, each.value.tags)

  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids = ingress.value.prefix_list_ids
      security_groups = ingress.value.security_groups
      self            = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      description     = egress.value.description
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids = egress.value.prefix_list_ids
      security_groups = egress.value.security_groups
      self            = egress.value.self
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── AWS Security Group Rules (standalone) ──────────────────────────────────
resource "aws_security_group_rule" "standalone_rules" {
  for_each = var.aws_standalone_rules

  type              = each.value.type
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  ipv6_cidr_blocks  = each.value.ipv6_cidr_blocks
  prefix_list_ids   = each.value.prefix_list_ids
  security_group_id = each.value.security_group_id
  self              = each.value.self
}

# ═══════════════════════════════════════════════════════════════════════════
# Azure Network Security Groups
# ═══════════════════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsgs" {
  for_each = var.azure_nsgs

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = merge(var.common_tags, each.value.tags)

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                                       = security_rule.value.name
      priority                                   = security_rule.value.priority
      direction                                  = security_rule.value.direction
      access                                     = security_rule.value.access
      protocol                                   = security_rule.value.protocol
      source_port_range                          = security_rule.value.source_port_range
      source_port_ranges                         = security_rule.value.source_port_ranges
      destination_port_range                     = security_rule.value.destination_port_range
      destination_port_ranges                    = security_rule.value.destination_port_ranges
      source_address_prefix                      = security_rule.value.source_address_prefix
      source_address_prefixes                    = security_rule.value.source_address_prefixes
      source_application_security_group_ids     = security_rule.value.source_application_security_group_ids
      destination_address_prefix                 = security_rule.value.destination_address_prefix
      destination_address_prefixes               = security_rule.value.destination_address_prefixes
      destination_application_security_group_ids = security_rule.value.destination_application_security_group_ids
    }
  }
}

# ── Azure NSG Subnet Associations ──────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_associations" {
  for_each = var.azure_subnet_nsg_associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.network_security_group_id
}

# ── Azure NSG NIC Associations ─────────────────────────────────────────────
resource "azurerm_network_interface_security_group_association" "nic_nsg_associations" {
  for_each = var.azure_nic_nsg_associations

  network_interface_id      = each.value.network_interface_id
  network_security_group_id = each.value.network_security_group_id
}

# ═══════════════════════════════════════════════════════════════════════════
# GCP Firewall Rules
# ═══════════════════════════════════════════════════════════════════════════

resource "google_compute_firewall" "firewall_rules" {
  for_each = var.gcp_firewall_rules

  name        = each.value.name
  network     = each.value.network
  description = each.value.description
  project     = each.value.project
  priority    = each.value.priority
  direction   = each.value.direction

  source_ranges      = each.value.source_ranges
  source_tags        = each.value.source_tags
  source_service_accounts = each.value.source_service_accounts
  destination_ranges = each.value.destination_ranges
  target_tags        = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts

  dynamic "allow" {
    for_each = each.value.allow_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny_rules
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  disabled = each.value.disabled
  log_config {
    metadata = each.value.log_config_metadata
  }
}

# ── GCP Firewall Policies ──────────────────────────────────────────────────
resource "google_compute_firewall_policy" "firewall_policies" {
  for_each = var.gcp_firewall_policies

  name        = each.value.name
  description = each.value.description
  parent      = each.value.parent
}

resource "google_compute_firewall_policy_rule" "firewall_policy_rules" {
  for_each = var.gcp_firewall_policy_rules

  firewall_policy = each.value.firewall_policy
  priority        = each.value.priority
  description     = each.value.description
  direction       = each.value.direction
  action          = each.value.action
  disabled        = each.value.disabled
  enable_logging  = each.value.enable_logging
  match {
    src_ip_ranges  = each.value.src_ip_ranges
    dest_ip_ranges = each.value.dest_ip_ranges
    layer4_configs {
      ip_protocol = each.value.ip_protocol
      ports       = each.value.ports
    }
  }
  target_resources = each.value.target_resources
  target_service_accounts = each.value.target_service_accounts
}

resource "google_compute_firewall_policy_association" "firewall_policy_associations" {
  for_each = var.gcp_firewall_policy_associations

  name              = each.value.name
  firewall_policy   = each.value.firewall_policy
  attachment_target = each.value.attachment_target
}
