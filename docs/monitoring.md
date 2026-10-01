# APEX-OS IAM/PAM — Monitoring & Observability Framework

**Version:** 1.0  
**Owner:** Platform Engineering / SRE  
**Last Updated:** 2026-10-01  
**Status:** Production-Ready

---

## Table of Contents

1. [Overview & Philosophy](#overview--philosophy)
2. [Architecture](#architecture)
3. [Prometheus Metrics](#prometheus-metrics)
4. [Grafana Dashboards](#grafana-dashboards)
5. [ELK Logging](#elk-logging)
6. [Jaeger Tracing](#jaeger-tracing)
7. [Alert Rules](#alert-rules)
8. [SLOs & SLAs](#slos--slas)
9. [Runbooks](#runbooks)
10. [Deployment & Operations](#deployment--operations)

---

## Overview & Philosophy

APEX-OS IAM/PAM is a critical identity security platform. Downtime or degraded performance directly impacts authentication, authorization, and privileged access across the entire organization. This framework ensures:

- **Proactive detection** of issues before users are impacted
- **Rapid root-cause analysis** through correlated metrics, logs, and traces
- **Measurable reliability** via SLOs tied to business outcomes
- **Audit compliance** through immutable, structured logging of all security events

### Observability Pillars

| Pillar | Tool | Purpose |
|--------|------|---------|
| Metrics | Prometheus + Alertmanager | Quantitative system health |
| Logs | ELK Stack (Elasticsearch, Logstash, Kibana) | Event forensics & audit trails |
| Traces | Jaeger | Distributed request flow analysis |
| Alerts | Alertmanager → PagerDuty/Slack | Human notification |
| SLOs | Grafana + Prometheus | Reliability guarantees |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        APEX-OS IAM/PAM Cluster                       │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │   Auth   │  │  Policy  │  │  Vault   │  │  Session │           │
│  │ Service  │  │  Engine  │  │  Service │  │  Manager │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │              │              │              │                  │
│       └──────────────┴──────────────┴──────────────┘                  │
│                              │                                        │
│                    ┌─────────┴─────────┐                              │
│                    │  Service Mesh     │                              │
│                    │  (Envoy/Istio)    │                              │
│                    └─────────┬─────────┘                              │
│                              │                                        │
│  ┌───────────────────────────┼───────────────────────────┐           │
│  │                           │                           │           │
│  ▼                           ▼                           ▼           │
│ ┌─────────────┐    ┌──────────────────┐    ┌──────────────────┐     │
│ │ Prometheus  │    │   Jaeger Agent   │    │  Filebeat/       │     │
│ │  (metrics)  │    │   (traces)       │    │  Fluentd (logs)  │     │
│ └──────┬──────┘    └────────┬─────────┘    └────────┬─────────┘     │
│        │                    │                        │               │
│        ▼                    ▼                        ▼               │
│ ┌─────────────┐    ┌──────────────────┐    ┌──────────────────┐     │
│ │ Alertmanager│    │   Jaeger         │    │   Logstash       │     │
│ │             │    │   Collector      │    │   (pipeline)     │     │
│ └──────┬──────┘    └────────┬─────────┘    └────────┬─────────┘     │
│        │                    │                        │               │
│        ▼                    ▼                        ▼               │
│ ┌─────────────┐    ┌──────────────────┐    ┌──────────────────┐     │
│ │ PagerDuty / │    │   Jaeger         │    │   Elasticsearch  │     │
│ │ Slack       │    │   Query/UI       │    │   Cluster        │     │
│ └─────────────┘    └──────────────────┘    └────────┬─────────┘     │
│                                                      │               │
│                                              ┌───────┴───────┐       │
│                                              │    Kibana     │       │
│                                              └───────────────┘       │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Grafana (Dashboards)                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Prometheus Metrics

### Metric Naming Convention

All metrics follow the pattern: `apexos_{subsystem}_{metric}_{unit}`

### Core Service Metrics

#### Authentication Service (`apexos_auth_*`)

```yaml
# Request rate
apexos_auth_requests_total{method, endpoint, status, tenant}
apexos_auth_request_duration_seconds{method, endpoint, status, tenant, le}

# Active sessions
apexos_auth_active_sessions{tenant, auth_type}
apexos_auth_session_duration_seconds{tenant, auth_type, le}

# Token operations
apexos_auth_token_issued_total{type, tenant}
apexos_auth_token_validated_total{type, tenant}
apexos_auth_token_revoked_total{reason, tenant}
apexos_auth_token_refresh_total{tenant}

# MFA
apexos_auth_mfa_challenges_total{type, result, tenant}
apexos_auth_mfa_duration_seconds{type, result, le}

# Failures
apexos_auth_failures_total{reason, source_ip_range, tenant}
apexos_auth_lockouts_total{tenant, user_id_hash}
apexos_auth_brute_force_detected_total{source_ip_range}
```

#### Policy Engine (`apexos_policy_*`)

```yaml
apexos_policy_evaluations_total{decision, policy_type, tenant}
apexos_policy_evaluation_duration_seconds{policy_type, le}
apexos_policy_cache_hits_total{cache_type}
apexos_policy_cache_misses_total{cache_type}
apexos_policy_cache_size{cache_type}
apexos_policy_sync_duration_seconds{source}
apexos_policy_sync_failures_total{source}
apexos_policy_version_load_errors_total
```

#### Vault / Secrets (`apexos_vault_*`)

```yaml
apexos_vault_secrets_read_total{secret_type, tenant}
apexos_vault_secrets_read_duration_seconds{secret_type, le}
apexos_vault_secrets_write_total{secret_type, tenant}
apexos_vault_secrets_rotation_total{status, secret_type}
apexos_vault_rotation_failures_total{secret_type, reason}
apexos_vault_unseal_operations_total{result}
apexos_vault_seal_status
apexos_vault_storage_backend_latency_seconds{operation, le}
```

#### Session Manager (`apexos_session_*`)

```yaml
apexos_session_active_total{tenant, session_type}
apexos_session_created_total{tenant, session_type}
apexos_session_terminated_total{reason, tenant}
apexos_session_duration_seconds{session_type, le}
apexos_session_concurrent_limit_hits_total{tenant}
apexos_session_recording_bytes_total{tenant}
```

#### Privileged Access Management (`apexos_pam_*`)

```yaml
apexos_pam_checkout_requests_total{resource_type, result, tenant}
apexos_pam_checkout_duration_seconds{resource_type, le}
apexos_pam_active_checkouts{resource_type, tenant}
apexos_pam_checkout_violations_total{violation_type, tenant}
apexos_pam_jumphost_sessions_active{tenant}
apexos_pam_jumphost_sessions_total{result, tenant}
apexos_pam_password_changes_total{resource_type, result, tenant}
apexos_pam_certificate_expiry_days{resource_id_hash}
```

### Infrastructure Metrics

```yaml
# Go runtime (all services)
apexos_go_goroutines
apexos_go_memory_bytes{type}
apexos_go_gc_duration_seconds{le}
apexos_go_threads

# HTTP/gRPC server
apexos_http_requests_total{method, route, status}
apexos_http_request_duration_seconds{method, route, le}
apexos_http_response_size_bytes{method, route, le}
apexos_grpc_requests_total{service, method, status}
apexos_grpc_duration_seconds{service, method, le}

# Database
apexos_db_connections_active{pool}
apexos_db_connections_idle{pool}
apexos_db_query_duration_seconds{operation, table, le}
apexos_db_query_errors_total{operation, table, reason}
apexos_db_transaction_duration_seconds{le}

# Cache (Redis)
apexos_cache_hits_total{cache_name}
apexos_cache_misses_total{cache_name}
apexos_cache_evictions_total{cache_name}
apexos_cache_memory_bytes{cache_name}
apexos_cache_operation_duration_seconds{operation, le}

# Message Queue
apexos_mq_messages_published_total{topic, status}
apexos_mq_messages_consumed_total{topic, consumer_group, status}
apexos_mq_consumer_lag{topic, consumer_group}
apexos_mq_processing_duration_seconds{topic, le}
```

### Custom Business Metrics

```yaml
apexos_users_provisioned_total{source, tenant}
apexos_users_deprovisioned_total{source, tenant}
apexos_access_reviews_completed_total{tenant}
apexos_access_reviews_overdue_total{tenant}
apexos_compliance_violations_total{policy, severity}
apexos_audit_log_entries_total{event_type, result}
```

### Prometheus Configuration

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
  external_labels:
    cluster: apexos-prod
    region: us-east-1

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
      timeout: 10s

scrape_configs:
  - job_name: 'apexos-auth'
    metrics_path: /metrics
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: apexos-auth
        action: keep

  - job_name: 'apexos-policy'
    metrics_path: /metrics
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: apexos-policy
        action: keep

  - job_name: 'apexos-vault'
    metrics_path: /metrics
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: apexos-vault
        action: keep

  - job_name: 'apexos-session'
    metrics_path: /metrics
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: apexos-session
        action: keep

  - job_name: 'apexos-pam'
    metrics_path: /metrics
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: apexos-pam
        action: keep

  - job_name: 'envoy-sidecar'
    metrics_path: /stats/prometheus
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_container_name]
        regex: istio-proxy
        action: keep

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['apexos']
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

---

## Grafana Dashboards

### Dashboard Inventory

| Dashboard | UID | Purpose | Refresh |
|-----------|-----|---------|---------|
| IAM Overview | `apexos-overview` | Executive health view | 30s |
| Auth Deep Dive | `apexos-auth` | Authentication analytics | 15s |
| Policy Engine | `apexos-policy` | Policy evaluation metrics | 15s |
| Vault & Secrets | `apexos-vault` | Secrets management health | 30s |
| PAM Operations | `apexos-pam` | Privileged access monitoring | 15s |
| Infrastructure | `apexos-infra` | K8s + DB + Cache health | 30s |
| SLO Compliance | `apexos-slo` | Error budget & burn rate | 1m |
| Security Events | `apexos-security` | Threat detection & audit | 15s |

### Dashboard: IAM Overview (`apexos-overview`)

```json
{
  "uid": "apexos-overview",
  "title": "APEX-OS IAM Overview",
  "tags": ["apexos", "iam", "overview"],
  "timezone": "utc",
  "refresh": "30s",
  "time": {"from": "now-6h", "to": "now"},
  "panels": [
    {
      "id": 1,
      "title": "Authentication Success Rate",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
      "targets": [{
        "expr": "sum(rate(apexos_auth_requests_total{status=~\"2..\"}[5m])) / sum(rate(apexos_auth_requests_total[5m])) * 100",
        "legendFormat": "Success %"
      }],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "red", "value": null},
              {"color": "yellow", "value": 99},
              {"color": "green", "value": 99.9}
            ]
          }
        }
      }
    },
    {
      "id": 2,
      "title": "Auth Request Rate",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 6, "y": 0},
      "targets": [{
        "expr": "sum(rate(apexos_auth_requests_total[1m])) by (method)",
        "legendFormat": "{{method}}"
      }]
    },
    {
      "id": 3,
      "title": "Auth Latency (p99)",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 18, "y": 0},
      "targets": [{
        "expr": "histogram_quantile(0.99, sum(rate(apexos_auth_request_duration_seconds_bucket[5m])) by (le, endpoint))",
        "legendFormat": "{{endpoint}}"
      }],
      "fieldConfig": {"defaults": {"unit": "s"}}
    },
    {
      "id": 4,
      "title": "Active Sessions",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 8, "x": 0, "y": 8},
      "targets": [{
        "expr": "sum(apexos_auth_active_sessions) by (auth_type)",
        "legendFormat": "{{auth_type}}"
      }]
    },
    {
      "id": 5,
      "title": "MFA Challenge Volume",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 8, "x": 8, "y": 8},
      "targets": [{
        "expr": "sum(rate(apexos_auth_mfa_challenges_total[5m])) by (type, result)",
        "legendFormat": "{{type}} - {{result}}"
      }]
    },
    {
      "id": 6,
      "title": "Policy Evaluation Rate",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 8, "x": 16, "y": 8},
      "targets": [{
        "expr": "sum(rate(apexos_policy_evaluations_total[1m])) by (decision)",
        "legendFormat": "{{decision}}"
      }]
    },
    {
      "id": 7,
      "title": "Error Budget Remaining",
      "type": "gauge",
      "gridPos": {"h": 8, "w": 6, "x": 0, "y": 16},
      "targets": [{
        "expr": "apexos:slo_error_budget:ratio",
        "legendFormat": "Auth SLO"
      }],
      "fieldConfig": {
        "defaults": {
          "unit": "percentunit",
          "min": 0,
          "max": 1,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "red", "value": null},
              {"color": "yellow", "value": 0.5},
              {"color": "green", "value": 0.8}
            ]
          }
        }
      }
    },
    {
      "id": 8,
      "title": "Vault Seal Status",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 16},
      "targets": [{
        "expr": "apexos_vault_seal_status",
        "legendFormat": "Sealed"
      }],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "red", "value": 1}
            ]
          }
        }
      }
    },
    {
      "id": 9,
      "title": "PAM Active Checkouts",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16},
      "targets": [{
        "expr": "sum(apexos_pam_active_checkouts) by (resource_type)",
        "legendFormat": "{{resource_type}}"
      }]
    }
  ]
}
```

### Dashboard: Auth Deep Dive (`apexos-auth`)

```json
{
  "uid": "apexos-auth",
  "title": "APEX-OS Auth Deep Dive",
  "tags": ["apexos", "auth"],
  "refresh": "15s",
  "time": {"from": "now-1h", "to": "now"},
  "panels": [
    {
      "id": 1,
      "title": "Login Success vs Failure",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
      "targets": [
        {"expr": "sum(rate(apexos_auth_requests_total{endpoint=\"/login\", status=~\"2..\"}[5m]))", "legendFormat": "Success"},
        {"expr": "sum(rate(apexos_auth_requests_total{endpoint=\"/login\", status=~\"4..\"}[5m]))", "legendFormat": "Client Error"},
        {"expr": "sum(rate(apexos_auth_requests_total{endpoint=\"/login\", status=~\"5..\"}[5m]))", "legendFormat": "Server Error"}
      ]
    },
    {
      "id": 2,
      "title": "Login Latency Distribution",
      "type": "heatmap",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "targets": [{
        "expr": "sum(rate(apexos_auth_request_duration_seconds_bucket{endpoint=\"/login\"}[5m])) by (le)",
        "legendFormat": "{{le}}"
      }]
    },
    {
      "id": 3,
      "title": "Token Operations",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
      "targets": [
        {"expr": "sum(rate(apexos_auth_token_issued_total[5m])) by (type)", "legendFormat": "Issued - {{type}}"},
        {"expr": "sum(rate(apexos_auth_token_revoked_total[5m])) by (reason)", "legendFormat": "Revoked - {{reason}}"}
      ]
    },
    {
      "id": 4,
      "title": "MFA Method Breakdown",
      "type": "piechart",
      "gridPos": {"h": 8, "w": 6, "x": 12, "y": 8},
      "targets": [{
        "expr": "sum(apexos_auth_mfa_challenges_total) by (type)",
        "legendFormat": "{{type}}"
      }]
    },
    {
      "id": 5,
      "title": "Top Failure Reasons",
      "type": "bargauge",
      "gridPos": {"h": 8, "w": 6, "x": 18, "y": 8},
      "targets": [{
        "expr": "topk(10, sum(rate(apexos_auth_failures_total[1h])) by (reason))",
        "legendFormat": "{{reason}}"
      }]
    },
    {
      "id": 6,
      "title": "Session Duration Distribution",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16},
      "targets": [{
        "expr": "histogram_quantile(0.5, sum(rate(apexos_auth_session_duration_seconds_bucket[1h])) by (le))",
        "legendFormat": "p50"
      }, {
        "expr": "histogram_quantile(0.95, sum(rate(apexos_auth_session_duration_seconds_bucket[1h])) by (le))",
        "legendFormat": "p95"
      }, {
        "expr": "histogram_quantile(0.99, sum(rate(apexos_auth_session_duration_seconds_bucket[1h])) by (le))",
        "legendFormat": "p99"
      }],
      "fieldConfig": {"defaults": {"unit": "s"}}
    },
    {
      "id": 7,
      "title": "Lockout Events",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16},
      "targets": [{
        "expr": "sum(rate(apexos_auth_lockouts_total[5m])) by (tenant)",
        "legendFormat": "{{tenant}}"
      }]
    }
  ]
}
```

### Dashboard: SLO Compliance (`apexos-slo`)

```json
{
  "uid": "apexos-slo",
  "title": "APEX-OS SLO Compliance",
  "tags": ["apexos", "slo", "reliability"],
  "refresh": "1m",
  "time": {"from": "now-30d", "to": "now"},
  "panels": [
    {
      "id": 1,
      "title": "Authentication Availability (30d)",
      "type": "stat",
      "gridPos": {"h": 6, "w": 6, "x": 0, "y": 0},
      "targets": [{
        "expr": "1 - (sum(increase(apexos_auth_requests_total{status=~\"5..\"}[30d])) / sum(increase(apexos_auth_requests_total[30d])))",
        "legendFormat": "Availability"
      }],
      "fieldConfig": {"defaults": {"unit": "percentunit", "decimals": 4}}
    },
    {
      "id": 2,
      "title": "Authentication Latency SLO (p99 < 500ms)",
      "type": "stat",
      "gridPos": {"h": 6, "w": 6, "x": 6, "y": 0},
      "targets": [{
        "expr": "histogram_quantile(0.99, sum(rate(apexos_auth_request_duration_seconds_bucket[30d])) by (le))",
        "legendFormat": "p99 Latency"
      }],
      "fieldConfig": {"defaults": {"unit": "s"}}
    },
    {
      "id": 3,
      "title": "Error Budget Burn Rate",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "targets": [{
        "expr": "apexos:slo_burn_rate:auth_availability",
        "legendFormat": "Auth Availability Burn Rate"
      }, {
        "expr": "apexos:slo_burn_rate:auth_latency",
        "legendFormat": "Auth Latency Burn Rate"
      }],
      "fieldConfig": {"defaults": {"unit": "short"}}
    },
    {
      "id": 4,
      "title": "Policy Engine Availability",
      "type": "stat",
      "gridPos": {"h": 6, "w": 6, "x": 0, "y": 6},
      "targets": [{
        "expr": "1 - (sum(increase(apexos_policy_evaluations_total{status=\"error\"}[30d])) / sum(increase(apexos_policy_evaluations_total[30d])))",
        "legendFormat": "Policy Availability"
      }],
      "fieldConfig": {"defaults": {"unit": "percentunit", "decimals": 4}}
    },
    {
      "id": 5,
      "title": "Vault Availability",
      "type": "stat",
      "gridPos": {"h": 6, "w": 6, "x": 6, "y": 6},
      "targets": [{
        "expr": "1 - (sum(increase(apexos_vault_secrets_read_total{status=\"error\"}[30d])) / sum(increase(apexos_vault_secrets_read_total[30d])))",
        "legendFormat": "Vault Availability"
      }],
      "fieldConfig": {"defaults": {"unit": "percentunit", "decimals": 4}}
    },
    {
      "id": 6,
      "title": "SLO Compliance Heatmap",
      "type": "heatmap",
      "gridPos": {"h": 10, "w": 24, "x": 0, "y": 12},
      "targets": [{
        "expr": "apexos:slo_compliance:ratio",
        "legendFormat": "{{slo_name}}"
      }]
    }
  ]
}
```

### Dashboard Provisioning

```yaml
# grafana/provisioning/dashboards/apexos.yml
apiVersion: 1

providers:
  - name: 'apexos'
    orgId: 1
    folder: 'APEX-OS'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards/apexos
```

---

## ELK Logging

### Log Pipeline Architecture

```
Application → Filebeat → Logstash → Elasticsearch → Kibana
                  ↓
            (direct for simple logs)
```

### Log Schema (ECS - Elastic Common Schema)

All logs MUST follow ECS 8.x format for consistency and Kibana compatibility.

```json
{
  "@timestamp": "2026-10-01T12:00:00.000Z",
  "log.level": "info",
  "message": "Authentication successful",
  "service.name": "apexos-auth",
  "service.version": "2.3.1",
  "service.environment": "production",
  "trace.id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span.id": "00f067aa0ba902b7",
  "transaction.id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "user.id": "user_abc123",
  "user.name_hash": "sha256:9f86d08...",
  "user.tenant_id": "tenant_prod_01",
  "source.ip": "10.0.1.100",
  "source.port": 54321,
  "http.request.method": "POST",
  "http.request.path": "/api/v2/auth/login",
  "http.response.status_code": 200,
  "event.action": "auth.login",
  "event.outcome": "success",
  "event.duration": 125000000,
  "event.severity": "info",
  "auth.method": "password+mfa",
  "auth.mfa_type": "totp",
  "auth.failure_reason": null,
  "auth.session_id": "sess_xyz789",
  "auth.token_type": "access",
  "auth.token_expiry": "2026-10-01T13:00:00Z",
  "policy.decision": null,
  "policy.evaluated": false,
  "vault.secret_path": null,
  "vault.operation": null,
  "pam.resource_id": null,
  "pam.checkout_id": null,
  "error.type": null,
  "error.message": null,
  "error.stack_trace": null,
  "process.pid": 12345,
  "process.name": "apexos-auth",
  "host.name": "apexos-auth-7d9f4b6c5-x2v8p",
  "kubernetes.namespace": "apexos",
  "kubernetes.pod.name": "apexos-auth-7d9f4b6c5-x2v8p",
  "kubernetes.node.name": "ip-10-0-1-50.ec2.internal",
  "labels.cluster": "apexos-prod",
  "labels.region": "us-east-1"
}
```

### Logstash Pipeline

```ruby
# logstash/pipeline/apexos.conf
input {
  beats {
    port => 5044
    type => "apexos"
  }
}

filter {
  if [type] == "apexos" {
    # Parse JSON if message is JSON
    json {
      source => "message"
      target => "parsed"
      skip_on_invalid_json => true
    }

    if [parsed] {
      mutate {
        merge => { "event" => "[parsed][event]" }
        merge => { "auth" => "[parsed][auth]" }
        merge => { "policy" => "[parsed][policy]" }
        merge => { "vault" => "[parsed][vault]" }
        merge => { "pam" => "[parsed][pam]" }
        merge => { "http" => "[parsed][http]" }
        merge => { "user" => "[parsed][user]" }
        merge => { "source" => "[parsed][source]" }
        merge => { "error" => "[parsed][error]" }
        merge => { "trace" => "[parsed][trace]" }
        merge => { "span" => "[parsed][span]" }
        merge => { "transaction" => "[parsed][transaction]" }
        merge => { "kubernetes" => "[parsed][kubernetes]" }
        merge => { "service" => "[parsed][service]" }
        merge => { "host" => "[parsed][host]" }
        merge => { "process" => "[parsed][process]" }
        merge => { "labels" => "[parsed][labels]" }
      }

      # Timestamp normalization
      date {
        match => ["[parsed][@timestamp]", "ISO8601"]
        target => "@timestamp"
      }

      # GeoIP enrichment for source IP
      if [source][ip] and [source][ip] !~ /^10\./ and [source][ip] !~ /^192\.168\./ {
        geoip {
          source => "[source][ip]"
          target => "source.geo"
          database => "/usr/share/GeoIP/GeoLite2-City.mmdb"
        }
      }

      # User agent parsing
      if [parsed][http][request][user_agent] {
        useragent {
          source => "[parsed][http][request][user_agent]"
          target => "user_agent"
        }
      }

      # Security event classification
      if [event][action] =~ /auth\.(login|logout|token)/ {
        mutate {
          add_tag => ["security", "authentication"]
        }
      }
      if [event][action] =~ /pam\./ {
        mutate {
          add_tag => ["security", "pam"]
        }
      }
      if [event][action] =~ /vault\./ {
        mutate {
          add_tag => ["security", "secrets"]
        }
      }
      if [event][outcome] == "failure" {
        mutate {
          add_tag => ["failure"]
        }
      }

      # Drop debug logs in production (keep for 7 days only)
      if [log][level] == "debug" and [service][environment] == "production" {
        mutate {
          add_field => { "[@metadata][ttl]" => "7d" }
        }
      }

      # Remove sensitive fields
      mutate {
        remove_field => [
          "[parsed]",
          "[auth][password]",
          "[auth][mfa_code]",
          "[auth][token]",
          "[auth][refresh_token]",
          "[vault][secret_value]",
          "[user][email]",
          "[user][phone]"
        ]
      }
    }
  }
}

output {
  if [type] == "apexos" {
    elasticsearch {
      hosts => ["https://elasticsearch:9200"]
      index => "apexos-%{+YYYY.MM.dd}"
      ilm_enabled => true
      ilm_rollover_alias => "apexos"
      ilm_pattern => "{now/d}-000001"
      ilm_policy => "apexos-lifecycle"
      user => "logstash_writer"
      password => "${ELASTIC_PASSWORD}"
      ssl => true
      ssl_certificate_verification => true
      cacert => "/etc/logstash/certs/ca.crt"
    }
  }
}
```

### Index Lifecycle Management (ILM)

```json
// elasticsearch/ilm/apexos-lifecycle.json
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d",
            "max_docs": 100000000
          },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "freeze": {},
          "set_priority": { "priority": 0 }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Index Templates

```json
// elasticsearch/templates/apexos-template.json
{
  "index_patterns": ["apexos-*"],
  "priority": 500,
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.refresh_interval": "5s",
      "index.mapping.total_fields.limit": 5000,
      "index.lifecycle.name": "apexos-lifecycle",
      "index.lifecycle.rollover_alias": "apexos"
    },
    "mappings": {
      "dynamic_templates": [
        {
          "strings_as_keywords": {
            "match_mapping_type": "string",
            "mapping": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        }
      ],
      "properties": {
        "@timestamp": { "type": "date" },
        "log.level": { "type": "keyword" },
        "message": { "type": "text", "analyzer": "standard" },
        "service.name": { "type": "keyword" },
        "service.version": { "type": "keyword" },
        "service.environment": { "type": "keyword" },
        "trace.id": { "type": "keyword" },
        "span.id": { "type": "keyword" },
        "transaction.id": { "type": "keyword" },
        "user.id": { "type": "keyword" },
        "user.name_hash": { "type": "keyword" },
        "user.tenant_id": { "type": "keyword" },
        "source.ip": { "type": "ip" },
        "source.port": { "type": "long" },
        "source.geo.location": { "type": "geo_point" },
        "http.request.method": { "type": "keyword" },
        "http.request.path": { "type": "keyword" },
        "http.response.status_code": { "type": "short" },
        "event.action": { "type": "keyword" },
        "event.outcome": { "type": "keyword" },
        "event.duration": { "type": "long" },
        "event.severity": { "type": "keyword" },
        "auth.method": { "type": "keyword" },
        "auth.mfa_type": { "type": "keyword" },
        "auth.failure_reason": { "type": "keyword" },
        "auth.session_id": { "type": "keyword" },
        "auth.token_type": { "type": "keyword" },
        "policy.decision": { "type": "keyword" },
        "policy.evaluated": { "type": "boolean" },
        "vault.secret_path": { "type": "keyword" },
        "vault.operation": { "type": "keyword" },
        "pam.resource_id": { "type": "keyword" },
        "pam.checkout_id": { "type": "keyword" },
        "error.type": { "type": "keyword" },
        "error.message": { "type": "text" },
        "process.pid": { "type": "long" },
        "process.name": { "type": "keyword" },
        "host.name": { "type": "keyword" },
        "kubernetes.namespace": { "type": "keyword" },
        "kubernetes.pod.name": { "type": "keyword" },
        "kubernetes.node.name": { "type": "keyword" }
      }
    }
  }
}
```

### Kibana Saved Searches & Visualizations

```yaml
# kibana/saved_objects/searches.yml
# Authentication Failures
- name: "Auth Failures (Last 1h)"
  searchSourceJSON:
    query:
      bool:
        must:
          - term: { event.outcome: "failure" }
          - term: { event.action: "auth.login" }
        filter:
          - range: { "@timestamp": { gte: "now-1h" } }

# Brute Force Attempts
- name: "Brute Force Detection"
  searchSourceJSON:
    query:
      bool:
        must:
          - term: { event.action: "auth.brute_force_detected" }
        filter:
          - range: { "@timestamp": { gte: "now-24h" } }

# PAM Checkout Activity
- name: "PAM Checkouts (Last 24h)"
  searchSourceJSON:
    query:
      bool:
        must:
          - wildcard: { event.action: "pam.checkout.*" }
        filter:
          - range: { "@timestamp": { gte: "now-24h" } }

# Vault Unseal Events
- name: "Vault Unseal Events"
  searchSourceJSON:
    query:
      bool:
        must:
          - term: { event.action: "vault.unseal" }

# Slow Auth Requests
- name: "Slow Auth Requests (>2s)"
  searchSourceJSON:
    query:
      bool:
        must:
          - range: { event.duration: { gte: 2000000000 } }
          - term: { event.action: "auth.login" }
        filter:
          - range: { "@timestamp": { gte: "now-1h" } }
```

### Filebeat Configuration

```yaml
# filebeat/filebeat.yml
filebeat.inputs:
  - type: container
    paths:
      - /var/log/containers/apexos-*.log
    json:
      keys_under_root: true
      add_error_key: true
    processors:
      - add_kubernetes_metadata:
          host: ${NODE_NAME}
          matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
      - decode_json_fields:
          fields: ["message"]
          target: "parsed"
          overwrite_keys: false
          add_error_key: true

  - type: log
    paths:
      - /var/log/apexos/*.log
    json.keys_under_root: true
    json.add_error_key: true

output.logstash:
  hosts: ["logstash:5044"]
  ssl.certificate_authorities: ["/etc/filebeat/certs/ca.crt"]
  ssl.certificate: "/etc/filebeat/certs/filebeat.crt"
  ssl.key: "/etc/filebeat/certs/filebeat.key"

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
```

---

## Jaeger Tracing

### Tracing Architecture

All services use OpenTelemetry SDK → OTLP → Jaeger Collector → Elasticsearch/Cassandra storage.

### OpenTelemetry Configuration

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 4000
    spike_limit_mib: 500
  resource:
    attributes:
      - key: service.namespace
        value: apexos
        action: upsert
      - key: deployment.environment
        value: production
        action: upsert
  tail_sampling:
    decision_wait: 10s
    num_traces: 100000
    expected_new_traces_per_sec: 1000
    policies:
      - name: errors
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: slow_requests
        type: latency
        latency: { threshold_ms: 500 }
      - name: auth_flows
        type: string_attribute
        string_attribute:
          key: http.route
          values: ["/api/v2/auth/login", "/api/v2/auth/token", "/api/v2/auth/mfa"]

exporters:
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: false
      cert_file: /etc/otel/certs/client.crt
      key_file: /etc/otel/certs/client.key
      ca_file: /etc/otel/certs/ca.crt
  elasticsearch:
    endpoints: ["https://elasticsearch:9200"]
    logs_index: jaeger-traces
    tls:
      ca_file: /etc/otel/certs/ca.crt

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, tail_sampling, batch, resource]
      exporters: [jaeger, elasticsearch]
```

### Span Naming Convention

```
{service}.{operation}

Examples:
  apexos.auth.login
  apexos.auth.token.validate
  apexos.auth.mfa.challenge
  apexos.policy.evaluate
  apexos.policy.cache.lookup
  apexos.vault.secret.read
  apexos.vault.secret.rotate
  apexos.session.create
  apexos.session.terminate
  apexos.pam.checkout
  apexos.pam.checkin
```

### Span Tags & Attributes

```go
// Standard span attributes for all services
const (
    // Service identification
    SpanAttributeServiceName    = "service.name"
    SpanAttributeServiceVersion = "service.version"
    SpanAttributeEnvironment    = "deployment.environment"

    // User context
    SpanAttributeUserID    = "user.id"
    SpanAttributeUserHash  = "user.name_hash"
    SpanAttributeTenantID  = "user.tenant_id"

    // Request context
    SpanAttributeHTTPMethod      = "http.method"
    SpanAttributeHTTPRoute       = "http.route"
    SpanAttributeHTTPStatusCode  = "http.status_code"
    SpanAttributeHTTPUserAgent   = "http.user_agent"

    // Auth-specific
    SpanAttributeAuthMethod     = "auth.method"
    SpanAttributeAuthMfaType    = "auth.mfa_type"
    SpanAttributeAuthOutcome     = "auth.outcome"
    SpanAttributeAuthFailureReason = "auth.failure_reason"
    SpanAttributeSessionID      = "auth.session_id"

    // Policy-specific
    SpanAttributePolicyID       = "policy.id"
    SpanAttributePolicyType     = "policy.type"
    SpanAttributePolicyDecision = "policy.decision"
    SpanAttributePolicyDuration = "policy.evaluation_duration_ms"

    // Vault-specific
    SpanAttributeVaultPath      = "vault.secret_path"
    SpanAttributeVaultOperation = "vault.operation"
    SpanAttributeVaultBackend   = "vault.backend"

    // PAM-specific
    SpanAttributePAMResourceID  = "pam.resource_id"
    SpanAttributePAMCheckoutID  = "pam.checkout_id"
    SpanAttributePAMResourceType = "pam.resource_type"

    // Database
    SpanAttributeDBSystem       = "db.system"
    SpanAttributeDBOperation    = "db.operation"
    SpanAttributeDBTable        = "db.table"
    SpanAttributeDBStatement    = "db.statement" // hashed

    // Cache
    SpanAttributeCacheName      = "cache.name"
    SpanAttributeCacheOperation = "cache.operation"
    SpanAttributeCacheHit       = "cache.hit"

    // Error
    SpanAttributeErrorType      = "error.type"
    SpanAttributeErrorMessage   = "error.message"
)
```

### Instrumentation Example (Go)

```go
// internal/tracing/tracing.go
package tracing

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("apexos")

// AuthLoginSpan creates a span for authentication login
func AuthLoginSpan(ctx context.Context, method, tenantID string) (context.Context, trace.Span) {
    ctx, span := tracer.Start(ctx, "apexos.auth.login",
        trace.WithAttributes(
            attribute.String("auth.method", method),
            attribute.String("user.tenant_id", tenantID),
            attribute.String("service.name", "apexos-auth"),
        ),
    )
    return ctx, span
}

// PolicyEvaluateSpan creates a span for policy evaluation
func PolicyEvaluateSpan(ctx context.Context, policyID, policyType string) (context.Context, trace.Span) {
    ctx, span := tracer.Start(ctx, "apexos.policy.evaluate",
        trace.WithAttributes(
            attribute.String("policy.id", policyID),
            attribute.String("policy.type", policyType),
            attribute.String("service.name", "apexos-policy"),
        ),
    )
    return ctx, span
}

// VaultReadSpan creates a span for vault secret read
func VaultReadSpan(ctx context.Context, path, operation string) (context.Context, trace.Span) {
    ctx, span := tracer.Start(ctx, "apexos.vault.secret.read",
        trace.WithAttributes(
            attribute.String("vault.secret_path", path),
            attribute.String("vault.operation", operation),
            attribute.String("service.name", "apexos-vault"),
        ),
    )
    return ctx, span
}

// PAMCheckoutSpan creates a span for PAM checkout
func PAMCheckoutSpan(ctx context.Context, resourceID, resourceType string) (context.Context, trace.Span) {
    ctx, span := tracer.Start(ctx, "apexos.pam.checkout",
        trace.WithAttributes(
            attribute.String("pam.resource_id", resourceID),
            attribute.String("pam.resource_type", resourceType),
            attribute.String("service.name", "apexos-pam"),
        ),
    )
    return ctx, span
}
```

### Jaeger Query UI Configuration

```yaml
# jaeger/jaeger-ui.json
{
  "monitor": {
    "menuEnabled": true
  },
  "dependencies": {
    "menuEnabled": true
  },
  "archiveEnabled": true,
  "tracking": {
    "gaTrackingID": "UA-XXXXX-Y"
  }
}
```

### Trace-Driven Alerting (Prometheus)

```yaml
# Alert on high trace error rate
- alert: HighTraceErrorRate
  expr: |
    sum(rate(traces_spanmetrics_calls_total{status_code="STATUS_CODE_ERROR"}[5m]))
    / sum(rate(traces_spanmetrics_calls_total[5m])) > 0.05
  for: 5m
  labels:
    severity: warning
    team: sre
  annotations:
    summary: "High trace error rate (> 5%)"
    description: "Error rate is {{ $value | humanizePercentage }} for the last 5 minutes."
    runbook: "https://wiki.internal/runbooks/high-trace-error-rate"
```

---

## Alert Rules

### Prometheus Alert Rules

```yaml
# prometheus/rules/apexos-alerts.yml
groups:
  # ─── Authentication Alerts ───
  - name: apexos-auth
    interval: 30s
    rules:
      - alert: AuthHighErrorRate
        expr: |
          sum(rate(apexos_auth_requests_total{status=~"5.."}[5m]))
          / sum(rate(apexos_auth_requests_total[5m])) > 0.01
        for: 2m
        labels:
          severity: critical
          team: sre
          service: auth
        annotations:
          summary: "Auth service error rate > 1%"
          description: "Auth error rate is {{ $value | humanizePercentage }} over 5m."
          runbook: "https://wiki.internal/runbooks/auth-high-error-rate"

      - alert: AuthHighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(apexos_auth_request_duration_seconds_bucket[5m])) by (le, endpoint)) > 1.0
        for: 5m
        labels:
          severity: warning
          team: sre
          service: auth
        annotations:
          summary: "Auth p99 latency > 1s for {{ $labels.endpoint }}"
          description: "p99 latency is {{ $value | humanizeDuration }}."
          runbook: "https://wiki.internal/runbooks/auth-high-latency"

      - alert: AuthBruteForceDetected
        expr: |
          sum(rate(apexos_auth_brute_force_detected_total[5m])) > 0
        for: 0m
        labels:
          severity: critical
          team: security
          service: auth
        annotations:
          summary: "Brute force attack detected"
          description: "Rate: {{ $value }}/s from {{ $labels.source_ip_range }}."
          runbook: "https://wiki.internal/runbooks/brute-force-detected"

      - alert: AuthLockoutSpike
        expr: |
          sum(rate(apexos_auth_lockouts_total[10m])) > 10
        for: 2m
        labels:
          severity: warning
          team: sre
          service: auth
        annotations:
          summary: "Unusual lockout spike"
          description: "Lockout rate: {{ $value }}/s across {{ $labels.tenant }}."

      - alert: MFASpike
        expr: |
          sum(rate(apexos_auth_mfa_challenges_total{result="failure"}[5m]))
          / sum(rate(apexos_auth_mfa_challenges_total[5m])) > 0.3
        for: 5m
        labels:
          severity: warning
          team: sre
          service: auth
        annotations:
          summary: "MFA failure rate > 30%"
          description: "MFA failure rate: {{ $value | humanizePercentage }}."

  # ─── Policy Engine Alerts ───
  - name: apexos-policy
    interval: 30s
    rules:
      - alert: PolicyHighErrorRate
        expr: |
          sum(rate(apexos_policy_evaluations_total{status="error"}[5m]))
          / sum(rate(apexos_policy_evaluations_total[5m])) > 0.005
        for: 3m
        labels:
          severity: critical
          team: sre
          service: policy
        annotations:
          summary: "Policy engine error rate > 0.5%"
          description: "Error rate: {{ $value | humanizePercentage }}."

      - alert: PolicyHighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(apexos_policy_evaluation_duration_seconds_bucket[5m])) by (le)) > 0.5
        for: 5m
        labels:
          severity: warning
          team: sre
          service: policy
        annotations:
          summary: "Policy evaluation p99 > 500ms"
          description: "p99: {{ $value | humanizeDuration }}."

      - alert: PolicyCacheHitRateLow
        expr: |
          sum(rate(apexos_policy_cache_hits_total[5m]))
          / (sum(rate(apexos_policy_cache_hits_total[5m])) + sum(rate(apexos_policy_cache_misses_total[5m]))) < 0.8
        for: 10m
        labels:
          severity: warning
          team: sre
          service: policy
        annotations:
          summary: "Policy cache hit rate < 80%"
          description: "Hit rate: {{ $value | humanizePercentage }}."

      - alert: PolicySyncFailure
        expr: |
          sum(rate(apexos_policy_sync_failures_total[15m])) > 0
        for: 5m
        labels:
          severity: critical
          team: sre
          service: policy
        annotations:
          summary: "Policy sync failures detected"
          description: "Source: {{ $labels.source }}, rate: {{ $value }}/s."

  # ─── Vault Alerts ───
  - name: apexos-vault
    interval: 30s
    rules:
      - alert: VaultSealed
        expr: apexos_vault_seal_status == 1
        for: 0m
        labels:
          severity: critical
          team: sre
          service: vault
        annotations:
          summary: "Vault is sealed!"
          description: "Vault seal status is 1 (sealed). Immediate action required."
          runbook: "https://wiki.internal/runbooks/vault-sealed"

      - alert: VaultUnsealFailure
        expr: |
          sum(rate(apexos_vault_unseal_operations_total{result="failure"}[5m])) > 0
        for: 0m
        labels:
          severity: critical
          team: sre
          service: vault
        annotations:
          summary: "Vault unseal operation failed"
          description: "Unseal failure rate: {{ $value }}/s."

      - alert: VaultRotationFailure
        expr: |
          sum(rate(apexos_vault_rotation_failures_total[1h])) > 0
        for: 5m
        labels:
          severity: warning
          team: sre
          service: vault
        annotations:
          summary: "Secret rotation failures"
          description: "Rotation failures: {{ $value }}/s for {{ $labels.secret_type }}."

      - alert: VaultHighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(apexos_vault_secrets_read_duration_seconds_bucket[5m])) by (le)) > 0.5
        for: 5m
        labels:
          severity: warning
          team: sre
          service: vault
        annotations:
          summary: "Vault read p99 > 500ms"
          description: "p99: {{ $value | humanizeDuration }}."

      - alert: VaultStorageBackendDegraded
        expr: |
          histogram_quantile(0.99, sum(rate(apexos_vault_storage_backend_latency_seconds_bucket[5m])) by (le, operation)) > 2.0
        for: 5m
        labels:
          severity: critical
          team: sre
          service: vault
        annotations:
          summary: "Vault storage backend p99 > 2s"
          description: "Operation: {{ $labels.operation }}, p99: {{ $value | humanizeDuration }}."

  # ─── PAM Alerts ───
  - name: apexos-pam
    interval: 30s
    rules:
      - alert: PAMCheckoutFailureRate
        expr: |
          sum(rate(apexos_pam_checkout_requests_total{result="failure"}[5m]))
          / sum(rate(apexos_pam_checkout_requests_total[5m])) > 0.05
        for: 3m
        labels:
          severity: critical
          team: sre
          service: pam
        annotations:
          summary: "PAM checkout failure rate > 5%"
          description: "Failure rate: {{ $value | humanizePercentage }}."

      - alert: PAMActiveCheckoutsHigh
        expr: |
          sum(apexos_pam_active_checkouts) > 100
        for: 10m
        labels:
          severity: warning
          team: sre
          service: pam
        annotations:
          summary: "High number of active PAM checkouts"
          description: "Active checkouts: {{ $value }}."

      - alert: PAMCheckoutViolation
        expr: |
          sum(rate(apexos_pam_checkout_violations_total[5m])) > 0
        for: 0m
        labels:
          severity: critical
          team: security
          service: pam
        annotations:
          summary: "PAM checkout violation detected"
          description: "Violation type: {{ $labels.violation_type }}, rate: {{ $value }}/s."

      - alert: PAMCertificateExpiringSoon
        expr: |
          apexos_pam_certificate_expiry_days < 30
        for: 1h
        labels:
          severity: warning
          team: sre
          service: pam
        annotations:
          summary: "PAM certificate expiring in < 30 days"
          description: "Resource: {{ $labels.resource_id_hash }}, days left: {{ $value }}."

  # ─── Infrastructure Alerts ───
  - name: apexos-infra
    interval: 30s
    rules:
      - alert: PodCrashLooping
        expr: |
          rate(kube_pod_container_status_restarts_total{namespace="apexos"}[15m]) > 0
        for: 5m
        labels:
          severity: critical
          team: sre
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
          description: "Restarts: {{ $value }}/s."

      - alert: PodHighMemory
        expr: |
          container_memory_working_set_bytes{namespace="apexos"}
          / container_spec_memory_limit_bytes{namespace="apexos"} > 0.85
        for: 5m
        labels:
          severity: warning
          team: sre
        annotations:
          summary: "Pod {{ $labels.pod }} memory usage > 85%"
          description: "Usage: {{ $value | humanizePercentage }}."

      - alert: PodHighCPU
        expr: |
          rate(container_cpu_usage_seconds_total{namespace="apexos"}[5m]) > 0.8
        for: 10m
        labels:
          severity: warning
          team: sre
        annotations:
          summary: "Pod {{ $labels.pod }} CPU usage > 80%"
          description: "CPU: {{ $value | humanizePercentage }}."

      - alert: DBConnectionPoolExhausted
        expr: |
          apexos_db_connections_active / (apexos_db_connections_active + apexos_db_connections_idle) > 0.9
        for: 5m
        labels:
          severity: critical
          team: sre
        annotations:
          summary: "DB connection pool > 90% utilized"
          description: "Pool: {{ $labels.pool }}, utilization: {{ $value | humanizePercentage }}."

      - alert: DBHighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(apexos_db_query_duration_seconds_bucket[5m])) by (le, operation)) > 1.0
        for: 5m
        labels:
          severity: warning
          team: sre
        annotations:
          summary: "DB query p99 > 1s"
          description: "Operation: {{ $labels.operation }}, p99: {{ $value | humanizeDuration }}."

      - alert: CacheHighEvictionRate
        expr: |
          sum(rate(apexos_cache_evictions_total[5m])) > 100
        for: 5m
        labels:
          severity: warning
          team: sre
        annotations:
          summary: "Cache eviction rate > 100/s"
          description: "Cache: {{ $labels.cache_name }}, evictions: {{ $value }}/s."

      - alert: MQConsumerLagHigh
        expr: |
          apexos_mq_consumer_lag > 10000
        for: 10m
        labels:
          severity: warning
          team: sre
        annotations:
          summary: "MQ consumer lag > 10,000"
          description: "Topic: {{ $labels.topic }}, group: {{ $labels.consumer_group }}, lag: {{ $value }}."

  # ─── Security Alerts ───
  - name: apexos-security
    interval: 30s
    rules:
      - alert: UnusualAuthPattern
        expr: |
          stddev by (source_ip_range) (sum(rate(apexos_auth_requests_total[10m])) by (source_ip_range))
          > 3 * avg by (source_ip_range) (sum(rate(apexos_auth_requests_total[10m])) by (source_ip_range))
        for: 5m
        labels:
          severity: warning
          team: security
        annotations:
          summary: "Unusual authentication pattern detected"
          description: "Source IP range {{ $labels.source_ip_range }} shows anomalous behavior."

      - alert: PrivilegedAccessAnomaly
        expr: |
          sum(rate(apexos_pam_checkout_requests_total{result="success"}[1h])) by (tenant)
          > 2 * avg_over_time(sum(rate(apexos_pam_checkout_requests_total{result="success"}[1h])) by (tenant)[24h:1h])
        for: 15m
        labels:
          severity: warning
          team: security
        annotations:
          summary: "Privileged access anomaly for tenant {{ $labels.tenant }}"
          description: "Checkout rate is 2x above 24h average."

      - alert: ComplianceViolationSpike
        expr: |
          sum(rate(apexos_compliance_violations_total[15m])) > 10
        for: 5m
        labels:
          severity: critical
          team: security
        annotations:
          summary: "Compliance violation spike"
          description: "Violations: {{ $value }}/s, policy: {{ $labels.policy }}."
```

### Alertmanager Configuration

```yaml
# alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@apexos.io'
  smtp_auth_username: 'alerts@apexos.io'
  smtp_auth_password: '${SMTP_PASSWORD}'
  slack_api_url: '${SLACK_WEBHOOK_URL}'
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'
  resolve_timeout: 5m

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  group_by: ['alertname', 'service', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default'
  routes:
    # Critical alerts → PagerDuty + Slack
    - matchers:
        - severity = "critical"
      receiver: 'critical'
      group_wait: 0s
      repeat_interval: 15m
      continue: true

    # Security alerts → Security team
    - matchers:
        - team = "security"
      receiver: 'security-team'
      group_wait: 0s
      repeat_interval: 30m

    # Warning alerts → Slack only
    - matchers:
        - severity = "warning"
      receiver: 'slack-warnings'
      group_wait: 1m
      repeat_interval: 2h

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'service']

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#apexos-alerts'
        send_resolved: true
        title: '{{ template "slack.default.title" . }}'
        text: '{{ template "slack.default.text" . }}'

  - name: 'critical'
    pagerduty_configs:
      - service_key: '${PAGERDUTY_SERVICE_KEY}'
        severity: critical
        description: '{{ .GroupLabels.alertname }}: {{ .CommonAnnotations.summary }}'
    slack_configs:
      - channel: '#apexos-critical'
        send_resolved: true
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ .CommonAnnotations.description }}'

  - name: 'security-team'
    pagerduty_configs:
      - service_key: '${PAGERDUTY_SECURITY_KEY}'
        severity: warning
        description: '{{ .GroupLabels.alertname }}: {{ .CommonAnnotations.summary }}'
    slack_configs:
      - channel: '#apexos-security'
        send_resolved: true
        title: '🔒 SECURITY: {{ .GroupLabels.alertname }}'
        text: '{{ .CommonAnnotations.description }}'

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#apexos-warnings'
        send_resolved: true
        title: '⚠️ WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ .CommonAnnotations.description }}'
```

---

## SLOs & SLAs

### Service Level Objectives

| Service | SLO | Measurement Window | Error Budget |
|---------|-----|-------------------|--------------|
| Authentication | 99.95% availability | 30 days | 21.9 min/month |
| Authentication Latency | p99 < 500ms | 30 days | — |
| Policy Engine | 99.99% availability | 30 days | 4.38 min/month |
| Policy Latency | p99 < 200ms | 30 days | — |
| Vault | 99.99% availability | 30 days | 4.38 min/month |
| Vault Latency | p99 < 300ms | 30 days | — |
| PAM | 99.9% availability | 30 days | 43.8 min/month |
| PAM Latency | p99 < 1s | 30 days | — |
| Session Manager | 99.95% availability | 30 days | 21.9 min/month |

### SLO Recording Rules (Prometheus)

```yaml
# prometheus/rules/slo-recording.yml
groups:
  - name: slo-recording
    interval: 30s
    rules:
      # ─── Authentication Availability ───
      - record: apexos:slo_error_budget:ratio
        expr: |
          1 - (
            sum(increase(apexos_auth_requests_total{status=~"5.."}[30d]))
            / sum(increase(apexos_auth_requests_total[30d]))
          )

      - record: apexos:slo_burn_rate:auth_availability
        expr: |
          (
            sum(increase(apexos_auth_requests_total{status=~"5.."}[1h]))
            / sum(increase(apexos_auth_requests_total[1h]))
          ) / (1 - 0.9995)

      - record: apexos:slo_burn_rate:auth_availability_6h
        expr: |
          (
            sum(increase(apexos_auth_requests_total{status=~"5.."}[6h]))
            / sum(increase(apexos_auth_requests_total[6h]))
          ) / (1 - 0.9995)

      # ─── Authentication Latency ───
      - record: apexos:slo_burn_rate:auth_latency
        expr: |
          (
            sum(increase(apexos_auth_request_duration_seconds_count{endpoint=~"/login|/token|/mfa"}[1h]))
            - sum(increase(apexos_auth_request_duration_seconds_bucket{endpoint=~"/login|/token|/mfa", le="0.5"}[1h]))
          ) / sum(increase(apexos_auth_request_duration_seconds_count{endpoint=~"/login|/token|/mfa"}[1h]))
          / (1 - 0.999)

      # ─── Policy Engine Availability ───
      - record: apexos:slo_error_budget:policy
        expr: |
          1 - (
            sum(increase(apexos_policy_evaluations_total{status="error"}[30d]))
            / sum(increase(apexos_policy_evaluations_total[30d]))
          )

      - record: apexos:slo_burn_rate:policy_availability
        expr: |
          (
            sum(increase(apexos_policy_evaluations_total{status="error"}[1h]))
            / sum(increase(apexos_policy_evaluations_total[1h]))
          ) / (1 - 0.9999)

      # ─── Vault Availability ───
      - record: apexos:slo_error_budget:vault
        expr: |
          1 - (
            sum(increase(apexos_vault_secrets_read_total{status="error"}[30d]))
            / sum(increase(apexos_vault_secrets_read_total[30d]))
          )

      - record: apexos:slo_burn_rate:vault_availability
        expr: |
          (
            sum(increase(apexos_vault_secrets_read_total{status="error"}[1h]))
            / sum(increase(apexos_vault_secrets_read_total[1h]))
          ) / (1 - 0.9999)

      # ─── PAM Availability ───
      - record: apexos:slo_error_budget:pam
        expr: |
          1 - (
            sum(increase(apexos_pam_checkout_requests_total{result="failure"}[30d]))
            / sum(increase(apexos_pam_checkout_requests_total[30d]))
          )

      - record: apexos:slo_burn_rate:pam_availability
        expr: |
          (
            sum(increase(apexos_pam_checkout_requests_total{result="failure"}[1h]))
            / sum(increase(apexos_pam_checkout_requests_total[1h]))
          ) / (1 - 0.999)

      # ─── Compliance ───
      - record: apexos:slo_compliance:ratio
        expr: |
          apexos:slo_error_budget:ratio * on() group_left()
          apexos:slo_error_budget:policy * on() group_left()
          apexos:slo_error_budget:vault * on() group_left()
          apexos:slo_error_budget:pam
```

### SLO Alert Rules

```yaml
# prometheus/rules/slo-alerts.yml
groups:
  - name: slo-alerts
    interval: 30s
    rules:
      # Fast burn: 2% budget in 1 hour
      - alert: SLOFastBurn_Auth
        expr: apexos:slo_burn_rate:auth_availability > 14.4
        for: 2m
        labels:
          severity: critical
          team: sre
          slo: auth
        annotations:
          summary: "Auth SLO fast burn (>14.4x)"
          description: "Error budget burning at {{ $value | humanizePercentage }} per hour."

      # Slow burn: 5% budget in 6 hours
      - alert: SLOSlowBurn_Auth
        expr: apexos:slo_burn_rate:auth_availability_6h > 6
        for: 15m
        labels:
          severity: warning
          team: sre
          slo: auth
        annotations:
          summary: "Auth SLO slow burn (>6x over 6h)"
          description: "Error budget burning at {{ $value | humanizePercentage }} per hour."

      - alert: SLOFastBurn_Policy
        expr: apexos:slo_burn_rate:policy_availability > 14.4
        for: 2m
        labels:
          severity: critical
          team: sre
          slo: policy
        annotations:
          summary: "Policy SLO fast burn (>14.4x)"
          description: "Error budget burning at {{ $value | humanizePercentage }} per hour."

      - alert: SLOFastBurn_Vault
        expr: apexos:slo_burn_rate:vault_availability > 14.4
        for: 2m
        labels:
          severity: critical
          team: sre
          slo: vault
        annotations:
          summary: "Vault SLO fast burn (>14.4x)"
          description: "Error budget burning at {{ $value | humanizePercentage }} per hour."

      - alert: SLOFastBurn_PAM
        expr: apexos:slo_burn_rate:pam_availability > 14.4
        for: 2m
        labels:
          severity: critical
          team: sre
          slo: pam
        annotations:
          summary: "PAM SLO fast burn (>14.4x)"
          description: "Error budget burning at {{ $value | humanizePercentage }} per hour."
```

### SLA Definitions (External-Facing)

| SLA Tier | Availability | Support Response | Resolution Target |
|----------|-------------|-----------------|-------------------|
| **Platinum** | 99.99% | 15 minutes | 4 hours |
| **Gold** | 99.95% | 30 minutes | 8 hours |
| **Silver** | 99.9% | 1 hour | 24 hours |
| **Bronze** | 99.5% | 4 hours | 72 hours |

### Error Budget Policy

| Budget Remaining | Action |
|-----------------|--------|
| > 50% | Normal operations |
| 25% – 50% | Freeze non-critical deployments; increase testing |
| 10% – 25% | Freeze all deployments; focus on reliability |
| < 10% | All hands on reliability; post-mortem required |
| 0% | Stop feature work; reliability sprint until budget recovers |

---

## Runbooks

### Runbook: Auth High Error Rate

```markdown
# Runbook: Auth High Error Rate

## Alert: AuthHighErrorRate

## Impact
Users unable to authenticate; potential lockout.

## Steps
1. Check Grafana dashboard `apexos-auth` for error breakdown
2. Query Kibana: `event.action: "auth.login" AND event.outcome: "failure"`
3. Check Jaeger for error traces: `service:apexos-auth AND status:ERROR`
4. Check recent deployments: `kubectl rollout history deployment/apexos-auth -n apexos`
5. Check DB connectivity: `apexos_db_connections_active{pool="auth"}`
6. Check cache: `apexos_cache_hits_total{cache_name="auth_sessions"}`

## Mitigations
- Rollback: `kubectl rollout undo deployment/apexos-auth -n apexos`
- Scale up: `kubectl scale deployment/apexos-auth --replicas=10 -n apexos`
- Circuit breaker: Enable via configmap `apexos-auth-circuit-breaker`

## Escalation
- L2: SRE on-call
- L3: Auth team lead
```

### Runbook: Vault Sealed

```markdown
# Runbook: Vault Sealed

## Alert: VaultSealed

## Impact
All secret operations failing; PAM checkouts blocked.

## Steps
1. Check Vault pod status: `kubectl get pods -n apexos -l app=apexos-vault`
2. Check Vault logs: `kubectl logs -n apexos -l app=apexos-vault --tail=100`
3. Check storage backend connectivity
4. If pod restarted, check unseal job: `kubectl get jobs -n apexos | grep unseal`

## Mitigations
- Manual unseal: `kubectl exec -n apexos vault-0 -- vault operator unseal`
- Auto-unseal: Verify auto-unseal configuration
- Failover: Activate DR vault cluster

## Escalation
- L2: SRE on-call
- L3: Vault team lead
- L4: CISO (if security incident)
```

---

## Deployment & Operations

### Docker Compose (Local Development)

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.47.0
    ports:
      - '9090:9090'
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/rules:/etc/prometheus/rules
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'

  alertmanager:
    image: prom/alertmanager:v0.26.0
    ports:
      - '9093:9093'
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-data:/alertmanager

  grafana:
    image: grafana/grafana:10.1.0
    ports:
      - '3000:3000'
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-clock-panel
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - grafana-data:/var/lib/grafana

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.10.0
    ports:
      - '9200:9200'
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - ES_JAVA_OPTS=-Xms2g -Xmx2g
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.10.0
    ports:
      - '5044:5044'
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logstash/certs:/etc/logstash/certs
    environment:
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}

  kibana:
    image: docker.elastic.co/kibana/kibana:8.10.0
    ports:
      - '5601:5601'
    environment:
      - ELASTICSEARCH_HOSTS=https://elasticsearch:9200
      - ELASTICSEARCH_PASSWORD=${ELASTIC_PASSWORD}

  jaeger-collector:
    image: jaegertracing/jaeger-collector:1.49
    ports:
      - '14250:14250'
      - '14268:14268'
    environment:
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=https://elasticsearch:9200
      - ES_USERNAME=elastic
      - ES_PASSWORD=${ELASTIC_PASSWORD}

  jaeger-query:
    image: jaegertracing/jaeger-query:1.49
    ports:
      - '16686:16686'
    environment:
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=https://elasticsearch:9200
      - ES_USERNAME=elastic
      - ES_PASSWORD=${ELASTIC_PASSWORD}

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.85.0
    ports:
      - '4317:4317'
      - '4318:4318'
    volumes:
      - ./otel/otel-collector-config.yaml:/etc/otel-collector-config.yaml
    command: ['--config=/etc/otel-collector-config.yaml']

volumes:
  prometheus-data:
  alertmanager-data:
  grafana-data:
  elasticsearch-data:
```

### Kubernetes Deployment (Helm Values)

```yaml
# helm/apexos-monitoring/values.yaml
prometheus:
  enabled: true
  retention: 30d
  storage: 50Gi
  resources:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 8Gi

alertmanager:
  enabled: true
  replicas: 3
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

grafana:
  enabled: true
  replicas: 2
  adminPassword: ${GRAFANA_ADMIN_PASSWORD}
  persistence:
    enabled: true
    size: 10Gi
  resources:
    requests:
      cpu: 250m
      memory: 512Mi

elasticsearch:
  enabled: true
  replicas: 3
  storage: 100Gi
  resources:
    requests:
      cpu: 1000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 16Gi

logstash:
  enabled: true
  replicas: 2
  resources:
    requests:
      cpu: 500m
      memory: 2Gi

kibana:
  enabled: true
  replicas: 2
  resources:
    requests:
      cpu: 250m
      memory: 1Gi

jaeger:
  enabled: true
  storage: elasticsearch
  resources:
    requests:
      cpu: 500m
      memory: 2Gi

otelCollector:
  enabled: true
  replicas: 2
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
```

### Health Check Endpoints

Every service MUST expose:

| Endpoint | Purpose |
|----------|---------|
| `/health` | Liveness probe (200 = alive) |
| `/ready` | Readiness probe (200 = ready to serve) |
| `/metrics` | Prometheus metrics |
| `/debug/pprof/` | Go pprof (disabled in prod) |

### Log Retention Policy

| Log Type | Hot Storage | Warm Storage | Cold Storage | Total |
|----------|-------------|--------------|--------------|-------|
| Security events | 7 days | 30 days | 1 year | 1 year |
| Auth logs | 7 days | 30 days | 90 days | 90 days |
| Audit logs | 30 days | 90 days | 7 years | 7 years |
| Debug logs | 7 days | — | — | 7 days |
| Infrastructure | 7 days | 30 days | 90 days | 90 days |

---

## Appendix

### A. Metric Cardinality Guidelines

- **High cardinality** (avoid): `user_id`, `session_id`, `request_id`, `ip_address`
- **Medium cardinality** (use sparingly): `tenant_id`, `source_ip_range`, `endpoint`
- **Low cardinality** (preferred): `status`, `method`, `service`, `environment`

### B. Label Naming Convention

- All labels: `snake_case`
- Boolean labels: `{label}_status` with values `true`/`false`
- Version labels: `service_version` (semver)
- Environment labels: `service_environment` (`production`, `staging`, `development`)

### C. Contact Matrix

| Severity | Primary | Secondary | Escalation |
|----------|---------|-----------|------------|
| Critical | SRE on-call | Auth/Vault team lead | CTO |
| Warning | SRE on-call | Service owner | Engineering manager |
| Security | Security team | SRE on-call | CISO |

### D. Key URLs (Production)

| Service | URL |
|---------|-----|
| Grafana | https://grafana.apexos.internal |
| Prometheus | https://prometheus.apexos.internal |
| Alertmanager | https://alertmanager.apexos.internal |
| Kibana | https://kibana.apexos.internal |
| Jaeger | https://jaeger.apexos.internal |

---

*End of document.*
