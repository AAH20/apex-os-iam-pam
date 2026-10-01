# APEX-OS IAM/PAM — Security Groups Module Variables

# ── AWS Variables ──────────────────────────────────────────────────────────
variable "aws_security_groups" {
  description = "Map of AWS security groups"
  type = map(object({
    name          = string
    description   = string
    vpc_id        = string
    ingress_rules = optional(list(object({
      description     = optional(string)
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      prefix_list_ids = optional(list(string), [])
      security_groups = optional(list(string), [])
      self            = optional(bool, false)
    })), [])
    egress_rules = optional(list(object({
      description     = optional(string)
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      prefix_list_ids = optional(list(string), [])
      security_groups = optional(list(string), [])
      self            = optional(bool, false)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "aws_standalone_rules" {
  description = "Map of standalone AWS security group rules"
  type = map(object({
    type              = string
    description       = optional(string)
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string), [])
    ipv6_cidr_blocks  = optional(list(string), [])
    prefix_list_ids   = optional(list(string), [])
    security_group_id = string
    self              = optional(bool, false)
  }))
  default = {}
}

# ── Azure Variables ────────────────────────────────────────────────────────
variable "azure_nsgs" {
  description = "Map of Azure NSGs"
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    security_rules = optional(list(object({
      name                                       = string
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string), [])
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string), [])
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string), [])
      source_application_security_group_ids     = optional(list(string), [])
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string), [])
      destination_application_security_group_ids = optional(list(string), [])
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "azure_subnet_nsg_associations" {
  description = "Map of subnet-NSG associations"
  type = map(object({
    subnet_id                 = string
    network_security_group_id = string
  }))
  default = {}
}

variable "azure_nic_nsg_associations" {
  description = "Map of NIC-NSG associations"
  type = map(object({
    network_interface_id      = string
    network_security_group_id = string
  }))
  default = {}
}

# ── GCP Variables ──────────────────────────────────────────────────────────
variable "gcp_firewall_rules" {
  description = "Map of GCP firewall rules"
  type = map(object({
    name                     = string
    network                  = string
    description              = optional(string)
    project                  = string
    priority                 = optional(number, 1000)
    direction                = optional(string, "INGRESS")
    source_ranges            = optional(list(string), [])
    source_tags              = optional(list(string), [])
    source_service_accounts  = optional(list(string), [])
    destination_ranges       = optional(list(string), [])
    target_tags              = optional(list(string), [])
    target_service_accounts  = optional(list(string), [])
    allow_rules = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny_rules = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    disabled = optional(bool, false)
    log_config_metadata = optional(string, "INCLUDE_ALL_METADATA")
  }))
  default = {}
}

variable "gcp_firewall_policies" {
  description = "Map of GCP firewall policies"
  type = map(object({
    name        = string
    description = optional(string)
    parent      = string
  }))
  default = {}
}

variable "gcp_firewall_policy_rules" {
  description = "Map of GCP firewall policy rules"
  type = map(object({
    firewall_policy = string
    priority        = number
    description     = optional(string)
    direction       = string
    action          = string
    disabled        = optional(bool, false)
    enable_logging  = optional(bool, true)
    src_ip_ranges   = optional(list(string), [])
    dest_ip_ranges  = optional(list(string), [])
    ip_protocol     = string
    ports           = optional(list(string), [])
    target_resources = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
  }))
  default = {}
}

variable "gcp_firewall_policy_associations" {
  description = "Map of GCP firewall policy associations"
  type = map(object({
    name              = string
    firewall_policy   = string
    attachment_target = string
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
