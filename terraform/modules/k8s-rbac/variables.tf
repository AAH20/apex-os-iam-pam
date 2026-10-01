# APEX-OS IAM/PAM — Kubernetes RBAC Module Variables

variable "namespaces" {
  description = "Map of Kubernetes namespaces to create"
  type = map(object({
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  }))
  default = {}
}

variable "roles" {
  description = "Map of Kubernetes Roles to create"
  type = map(object({
    namespace = string
    labels    = optional(map(string), {})
    rules = list(object({
      api_groups     = list(string)
      resources      = list(string)
      resource_names = optional(list(string), [])
      verbs          = list(string)
    }))
  }))
  default = {}
}

variable "cluster_roles" {
  description = "Map of Kubernetes ClusterRoles to create"
  type = map(object({
    labels = optional(map(string), {})
    rules = list(object({
      api_groups     = list(string)
      resources      = list(string)
      resource_names = optional(list(string), [])
      verbs          = list(string)
    }))
    aggregation_rule = optional(object({
      match_labels = map(string)
      match_expressions = list(object({
        key      = string
        operator = string
        values   = list(string)
      }))
    }))
  }))
  default = {}
}

variable "role_bindings" {
  description = "Map of Kubernetes RoleBindings to create"
  type = map(object({
    namespace     = string
    labels        = optional(map(string), {})
    role_ref_kind = string
    role_ref_name = string
    subjects = list(object({
      kind      = string
      name      = string
      namespace = optional(string)
      api_group = optional(string)
    }))
  }))
  default = {}
}

variable "cluster_role_bindings" {
  description = "Map of Kubernetes ClusterRoleBindings to create"
  type = map(object({
    labels = optional(map(string), {})
    role_ref_name = string
    subjects = list(object({
      kind      = string
      name      = string
      namespace = optional(string)
      api_group = optional(string)
    }))
  }))
  default = {}
}

variable "service_accounts" {
  description = "Map of Kubernetes ServiceAccounts to create"
  type = map(object({
    namespace                        = string
    labels                           = optional(map(string), {})
    annotations                      = optional(map(string), {})
    automount_service_account_token = optional(bool, true)
  }))
  default = {}
}

variable "pod_security_policies" {
  description = "Map of Pod Security Policies to create"
  type = map(object({
    labels = optional(map(string), {})
    privileged = optional(bool, false)
    allow_privilege_escalation = optional(bool, false)
    default_allow_privilege_escalation = optional(bool, false)
    required_drop_capabilities = optional(list(string), ["ALL"])
    allowed_capabilities = optional(list(string), [])
    volumes = optional(list(string), ["configMap", "emptyDir", "projected", "secret", "downwardAPI", "persistentVolumeClaim"])
    host_network = optional(bool, false)
    host_ports_min = optional(number, 0)
    host_ports_max = optional(number, 65535)
    host_ipc = optional(bool, false)
    host_pid = optional(bool, false)
    run_as_user_rule = optional(string, "RunAsAny")
    run_as_user_ranges = optional(list(object({
      min = number
      max = number
    })), [])
    se_linux_rule = optional(string, "RunAsAny")
    se_linux_options = optional(list(object({
      level = string
      role  = string
      type  = string
      user  = string
    })), [])
    supplemental_groups_rule = optional(string, "RunAsAny")
    supplemental_groups_ranges = optional(list(object({
      min = number
      max = number
    })), [])
    fs_group_rule = optional(string, "RunAsAny")
    fs_group_ranges = optional(list(object({
      min = number
      max = number
    })), [])
    read_only_root_filesystem = optional(bool, false)
  }))
  default = {}
}

variable "network_policies" {
  description = "Map of Network Policies to create"
  type = map(object({
    namespace = string
    labels    = optional(map(string), {})
    pod_selector_match_labels = map(string)
    pod_selector_match_expressions = optional(list(object({
      key      = string
      operator = string
      values   = list(string)
    })), [])
    policy_types = list(string)
    ingress = optional(list(object({
      from = list(object({
        pod_selector_match_labels = optional(map(string), {})
        namespace_selector_match_labels = optional(map(string), {})
        ip_block_cidr   = optional(string)
        ip_block_except = optional(list(string), [])
      }))
      ports = optional(list(object({
        protocol = optional(string, "TCP")
        port     = string
      })), [])
    })), [])
    egress = optional(list(object({
      to = list(object({
        pod_selector_match_labels = optional(map(string), {})
        namespace_selector_match_labels = optional(map(string), {})
        ip_block_cidr   = optional(string)
        ip_block_except = optional(list(string), [])
      }))
      ports = optional(list(object({
        protocol = optional(string, "TCP")
        port     = string
      })), [])
    })), [])
  }))
  default = {}
}

variable "common_labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    ManagedBy = "APEX-OS-IAM-PAM"
  }
}
