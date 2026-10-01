# APEX-OS IAM/PAM Helm Chart

A comprehensive Kubernetes Helm chart for deploying the APEX-OS Identity and Access Management (IAM) with Privileged Access Management (PAM) platform.

## Architecture

```
                    ┌─────────────┐
                    │   Ingress   │
                    │  (nginx)    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ API Gateway │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
  ┌─────▼─────┐    ┌──────▼──────┐    ┌─────▼─────┐
  │   Auth    │    │ Authorization│    │  Session  │
  │  Service  │    │   Service    │    │  Service  │
  └─────┬─────┘    └──────┬──────┘    └─────┬─────┘
        │                  │                  │
  ┌─────▼─────┐    ┌──────▼──────┐    ┌─────▼─────┐
  │   PAM     │    │    Vault     │    │   Audit   │
  │  Service  │    │   Service    │    │  Service  │
  └─────┬─────┘    └──────┬──────┘    └─────┬─────┘
        │                  │                  │
  ┌─────▼─────┐    ┌──────▼──────┐    ┌─────▼─────┐
  │   User    │    │   Policy     │    │  Web UI   │
  │ Directory │    │   Engine     │    │           │
  └───────────┘    └─────────────┘    └───────────┘
```

## Components

| Component | Description | Default Replicas |
|-----------|-------------|------------------|
| API Gateway | Central routing, rate limiting, CORS | 2 |
| Auth Service | Authentication (OAuth2, SAML, LDAP, MFA) | 3 |
| Authorization Service | RBAC/ABAC policy enforcement | 2 |
| Session Service | Session management and recording | 2 |
| PAM Service | Privileged access management | 2 |
| Vault Service | Secret storage and dynamic credentials | 2 |
| Audit Service | Audit logging and SIEM integration | 2 |
| User Directory | LDAP/SCIM user management | 2 |
| Policy Engine | OPA/Rego policy evaluation | 2 |
| Web UI | React-based management console | 2 |

## Prerequisites

- Kubernetes 1.25+
- Helm 3.12+
- Ingress controller (nginx recommended)
- cert-manager (for TLS certificates)
- Prometheus Operator (for monitoring)

## Installation

```bash
# Add the repository (if applicable)
helm repo add apex-os https://charts.apex-os.io
helm repo update

# Install the chart
helm install apex-os-iam-pam apex-os/apex-os-iam-pam \
  --namespace apex-os \
  --create-namespace \
  --values values.yaml

# Or install with custom values
helm install apex-os-iam-pam ./helm \
  --namespace apex-os \
  --create-namespace \
  --set global.domain=iam.example.com \
  --set ingress.hosts[0].host=iam.example.com
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.environment` | Deployment environment | `production` |
| `global.domain` | Base domain | `apex-os.io` |
| `image.tag` | Image tag for all services | `1.0.0` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class | `nginx` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `monitoring.enabled` | Enable monitoring stack | `true` |
| `security.networkPolicies.enabled` | Enable network policies | `true` |

### Feature Flags

| Feature | Description | Default |
|---------|-------------|---------|
| `features.zeroTrust` | Zero trust architecture | `true` |
| `features.passwordless` | Passwordless authentication | `true` |
| `features.biometricAuth` | Biometric authentication | `false` |
| `features.riskBasedAuth` | Risk-based authentication | `true` |
| `features.sessionAnomalyDetection` | Session anomaly detection | `true` |
| `features.credentialTheftDetection` | Credential theft detection | `true` |

## Monitoring

The chart includes a full monitoring stack:

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards
- **Jaeger**: Distributed tracing
- **ServiceMonitor**: Auto-discovery of service metrics
- **PrometheusRule**: Pre-configured alert rules

### Access Monitoring

```bash
# Grafana
kubectl port-forward svc/apex-os-iam-pam-grafana 3001:3000 -n apex-os

# Prometheus
kubectl port-forward svc/apex-os-iam-pam-prometheus 9090:9090 -n apex-os

# Jaeger
kubectl port-forward svc/apex-os-iam-pam-jaeger 16686:16686 -n apex-os
```

## Security

- Network policies (default deny + explicit allow)
- Pod security contexts (non-root, read-only root FS)
- RBAC with least privilege
- Secrets auto-generated on first install
- TLS via cert-manager

## Testing

```bash
# Run Helm tests
helm test apex-os-iam-pam -n apex-os
```

## Upgrading

```bash
helm upgrade apex-os-iam-pam ./helm \
  --namespace apex-os \
  --values values.yaml
```

## Uninstalling

```bash
helm uninstall apex-os-iam-pam -n apex-os
```

## License

Proprietary - APEX-OS
