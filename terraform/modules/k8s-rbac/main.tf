# APEX-OS IAM/PAM — Kubernetes RBAC Module
# Manages Kubernetes Roles, ClusterRoles, RoleBindings, and ClusterRoleBindings

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# ── Namespaces ─────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "namespaces" {
  for_each = var.namespaces

  metadata {
    name = each.key
    labels = merge(var.common_labels, each.value.labels)
    annotations = each.value.annotations
  }
}

# ── Roles (Namespace-scoped) ───────────────────────────────────────────────
resource "kubernetes_role" "roles" {
  for_each = var.roles

  metadata {
    name      = each.key
    namespace = each.value.namespace
    labels    = merge(var.common_labels, each.value.labels)
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups     = rule.value.api_groups
      resources      = rule.value.resources
      resource_names = rule.value.resource_names
      verbs          = rule.value.verbs
    }
  }
}

# ── ClusterRoles (Cluster-scoped) ──────────────────────────────────────────
resource "kubernetes_cluster_role" "cluster_roles" {
  for_each = var.cluster_roles

  metadata {
    name   = each.key
    labels = merge(var.common_labels, each.value.labels)
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups     = rule.value.api_groups
      resources      = rule.value.resources
      resource_names = rule.value.resource_names
      verbs          = rule.value.verbs
    }
  }

  dynamic "aggregation_rule" {
    for_each = each.value.aggregation_rule != null ? [each.value.aggregation_rule] : []
    content {
      cluster_role_selectors {
        match_labels = aggregation_rule.value.match_labels
        dynamic "match_expressions" {
          for_each = aggregation_rule.value.match_expressions
          content {
            key      = match_expressions.value.key
            operator = match_expressions.value.operator
            values   = match_expressions.value.values
          }
        }
      }
    }
  }
}

# ── RoleBindings (Namespace-scoped) ────────────────────────────────────────
resource "kubernetes_role_binding" "role_bindings" {
  for_each = var.role_bindings

  metadata {
    name      = each.key
    namespace = each.value.namespace
    labels    = merge(var.common_labels, each.value.labels)
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = each.value.role_ref_kind
    name      = each.value.role_ref_name
  }

  dynamic "subject" {
    for_each = each.value.subjects
    content {
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = subject.value.namespace
      api_group = subject.value.api_group
    }
  }
}

# ── ClusterRoleBindings (Cluster-scoped) ───────────────────────────────────
resource "kubernetes_cluster_role_binding" "cluster_role_bindings" {
  for_each = var.cluster_role_bindings

  metadata {
    name   = each.key
    labels = merge(var.common_labels, each.value.labels)
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = each.value.role_ref_name
  }

  dynamic "subject" {
    for_each = each.value.subjects
    content {
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = subject.value.namespace
      api_group = subject.value.api_group
    }
  }
}

# ── ServiceAccounts ────────────────────────────────────────────────────────
resource "kubernetes_service_account" "service_accounts" {
  for_each = var.service_accounts

  metadata {
    name      = each.key
    namespace = each.value.namespace
    labels    = merge(var.common_labels, each.value.labels)
    annotations = each.value.annotations
  }

  automount_service_account_token = each.value.automount_service_account_token
}

# ── Pod Security Policies (deprecated in 1.25+, use Pod Security Standards) ─
resource "kubernetes_pod_security_policy" "psps" {
  for_each = var.pod_security_policies

  metadata {
    name   = each.key
    labels = merge(var.common_labels, each.value.labels)
  }

  spec {
    privileged                 = each.value.privileged
    allow_privilege_escalation  = each.value.allow_privilege_escalation
    default_allow_privilege_escalation = each.value.default_allow_privilege_escalation
    required_drop_capabilities  = each.value.required_drop_capabilities
    allowed_capabilities        = each.value.allowed_capabilities
    volumes                     = each.value.volumes
    host_network                = each.value.host_network
    host_ports {
      min = each.value.host_ports_min
      max = each.value.host_ports_max
    }
    host_ipc                   = each.value.host_ipc
    host_pid                   = each.value.host_pid
    run_as_user {
      rule = each.value.run_as_user_rule
      dynamic "range" {
        for_each = each.value.run_as_user_ranges
        content {
          min = range.value.min
          max = range.value.max
        }
      }
    }
    se_linux {
      rule = each.value.se_linux_rule
      dynamic "se_linux_options" {
        for_each = each.value.se_linux_options
        content {
          level = se_linux_options.value.level
          role  = se_linux_options.value.role
          type  = se_linux_options.value.type
          user  = se_linux_options.value.user
        }
      }
    }
    supplemental_groups {
      rule = each.value.supplemental_groups_rule
      dynamic "range" {
        for_each = each.value.supplemental_groups_ranges
        content {
          min = range.value.min
          max = range.value.max
        }
      }
    }
    fs_group {
      rule = each.value.fs_group_rule
      dynamic "range" {
        for_each = each.value.fs_group_ranges
        content {
          min = range.value.min
          max = range.value.max
        }
      }
    }
    read_only_root_filesystem = each.value.read_only_root_filesystem
  }
}

# ── Network Policies ───────────────────────────────────────────────────────
resource "kubernetes_network_policy" "network_policies" {
  for_each = var.network_policies

  metadata {
    name      = each.key
    namespace = each.value.namespace
    labels    = merge(var.common_labels, each.value.labels)
  }

  spec {
    pod_selector {
      match_labels = each.value.pod_selector_match_labels
      dynamic "match_expressions" {
        for_each = each.value.pod_selector_match_expressions
        content {
          key      = match_expressions.value.key
          operator = match_expressions.value.operator
          values   = match_expressions.value.values
        }
      }
    }

    policy_types = each.value.policy_types

    dynamic "ingress" {
      for_each = each.value.ingress
      content {
        dynamic "from" {
          for_each = ingress.value.from
          content {
            pod_selector {
              match_labels = from.value.pod_selector_match_labels
            }
            namespace_selector {
              match_labels = from.value.namespace_selector_match_labels
            }
            ip_block {
              cidr   = from.value.ip_block_cidr
              except = from.value.ip_block_except
            }
          }
        }
        dynamic "ports" {
          for_each = ingress.value.ports
          content {
            protocol = ports.value.protocol
            port     = ports.value.port
          }
        }
      }
    }

    dynamic "egress" {
      for_each = each.value.egress
      content {
        dynamic "to" {
          for_each = egress.value.to
          content {
            pod_selector {
              match_labels = to.value.pod_selector_match_labels
            }
            namespace_selector {
              match_labels = to.value.namespace_selector_match_labels
            }
            ip_block {
              cidr   = to.value.ip_block_cidr
              except = to.value.ip_block_except
            }
          }
        }
        dynamic "ports" {
          for_each = egress.value.ports
          content {
            protocol = ports.value.protocol
            port     = ports.value.port
          }
        }
      }
    }
  }
}
