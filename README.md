# APEX-OS IAM/PAM

**Identity & Access Management / Privileged Access Management Platform**

APEX-OS IAM/PAM is an open-source identity security platform that unifies authentication, authorization, secrets management, zero-trust access, privileged session management, deception technology, and workload identity into a single, cohesive system. Built for organizations that demand defense-in-depth without vendor lock-in.

---

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Architecture Summary](#2-architecture-summary)
- [3. Quick Start](#3-quick-start)
- [4. Component Documentation](#4-component-documentation)
- [5. API Reference](#5-api-reference)
- [6. Deployment Guide](#6-deployment-guide)
- [7. Security Considerations](#7-security-considerations)
- [8. License](#8-license)

---

## 1. Project Overview

### What is APEX-OS IAM/PAM?

APEX-OS IAM/PAM is a comprehensive identity security platform that provides:

| Capability | Component | Purpose |
|---|---|---|
| **Identity Provider (IdP)** | Keycloak | SSO, MFA, user federation, identity brokering |
| **Secrets Management** | HashiCorp Vault | Dynamic secrets, encryption as service, PKI |
| **Policy Engine** | OPA / Cedar | Fine-grained authorization, policy-as-code |
| **Zero-Trust Proxy** | Pomerium | Identity-aware access proxy, mTLS |
| **Privileged Access Management** | Teleport | Just-in-time access, session recording, audit |
| **Deception Technology** | Thinkst Canary | Canary tokens, honeypots, early breach detection |
| **Workload Identity** | SPIFFE / SPIRE | Cryptographic workload identity, mTLS everywhere |

### Design Principles

- **Zero Trust** — Never trust, always verify. Every request is authenticated and authorized.
- **Defense in Depth** — Multiple independent security layers; compromise of one does not compromise all.
- **Least Privilege** — Just-in-time, just-enough access with automatic revocation.
- **Audit Everything** — Immutable audit logs for every authentication, authorization, and access event.
- **Open Source** — AGPL-3.0 licensed. No proprietary black boxes.

### Target Use Cases

- Enterprise SSO and workforce identity
- Kubernetes and cloud infrastructure access
- Privileged access to production systems
- Secrets rotation and dynamic credential issuance
- Compliance-driven access controls (SOC 2, HIPAA, PCI-DSS, FedRAMP)
- Threat detection via deception

---

## 2. Architecture Summary

### High-Level Architecture

```mermaid
graph TB
    subgraph "Users & Workloads"
        U[End Users]
        K8S[Kubernetes Pods]
        SVC[Microservices]
        DBA[Database Admins]
    end

    subgraph "Access Layer"
        POM[Pomerium<br/>Zero-Trust Proxy]
        TEL[Teleport<br/>PAM Gateway]
    end

    subgraph "Identity & Policy"
        KC[Keycloak<br/>IdP / SSO]
        OPA[OPA / Cedar<br/>Policy Engine]
        SPIRE[SPIRE<br/>Workload Identity]
    end

    subgraph "Secrets & Infrastructure"
        VAULT[HashiCorp Vault<br/>Secrets & PKI]
        CANARY[Thinkst Canary<br/>Deception]
    end

    subgraph "Target Resources"
        DB[(Databases)]
        SRV[Servers / SSH]
        K8SAPI[K8s API]
        CLOUD[Cloud APIs]
    end

    U -->|HTTPS/mTLS| POM
    DBA -->|Certificate| TEL
    K8S -->|SPIFFE SVID| SPIRE
    SVC -->|SPIFFE SVID| SPIRE

    POM -->|Token| KC
    POM -->|AuthZ Decision| OPA
    TEL -->|Token| KC
    TEL -->|AuthZ Decision| OPA

    KC -->|User Federation| VAULT
    OPA -->|Secrets| VAULT
    TEL -->|Dynamic Credentials| VAULT
    SPIRE -->|X.509 SVID| VAULT

    POM -->|Authorized| DB
    POM -->|Authorized| SRV
    TEL -->|Session| SRV
    TEL -->|Session| K8SAPI
    TEL -->|Session| CLOUD

    CANARY -.->|Alert| VAULT
    CANARY -.->|Alert| KC
```

### Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant P as Pomerium
    participant K as Keycloak
    participant O as OPA
    participant R as Resource

    U->>P: HTTPS Request (mTLS)
    P->>K: OIDC Authorization Code Flow
    K->>U: Login Page (MFA Challenge)
    U->>K: Credentials + TOTP
    K->>P: ID Token + Access Token
    P->>O: Authorization Request (token + resource + action)
    O->>P: Allow / Deny Decision
    alt Allow
        P->>R: Forward Request (with identity headers)
        R->>P: Response
        P->>U: Response
    else Deny
        P->>U: 403 Forbidden
    end
```

### Privileged Access Flow (Teleport)

```mermaid
sequenceDiagram
    participant A as Admin
    participant T as Teleport
    participant K as Keycloak
    participant V as Vault
    participant S as Target Server

    A->>T: tsh login --proxy=teleport.apex.local
    T->>K: SSO Authentication
    K->>A: WebAuthn / MFA Challenge
    A->>T: Authenticator Response
    T->>A: Short-lived Client Certificate

    A->>T: tsh ssh admin@prod-db-01
    T->>V: Request Dynamic Credentials
    V->>T: Database Credentials (TTL: 1h)
    T->>S: SSH Session (certificate-based)
    S->>T: Session Established
    T->>T: Record Session (audit log)
    T->>A: Interactive Session

    Note over T,S: Session auto-expires after TTL
    T->>V: Revoke Credentials
```

### Workload Identity Flow (SPIFFE/SPIRE)

```mermaid
sequenceDiagram
    participant W as Workload (Pod)
    participant S as SPIRE Agent
    participant SR as SPIRE Server
    participant V as Vault
    participant P as Target Service

    W->>S: Workload API Request (Unix Socket)
    S->>SR: Node Attestation
    SR->>S: SVID (X.509 Certificate)
    S->>W: SVID + Trust Bundle

    W->>P: mTLS Connection (SVID)
    P->>V: Validate SVID (SPIFFE ID)
    V->>P: Valid + Policy Match
    P->>W: Authorized Response
```

### Policy Decision Flow (OPA/Cedar)

```mermaid
flowchart LR
    REQ[Request Context] -->|input| OPA[OPA / Cedar Engine]
    POL[Policy Rego / Cedar] -->|data| OPA
    IDP[Identity Claims] -->|input| OPA
    SEC[Vault Secrets] -->|input| OPA
    OPA -->|allow / deny| RES[Resource Proxy]
    RES -->|forward / reject| CLIENT[Client]
```

---

## 3. Quick Start

### Prerequisites

- Docker 24.0+
- Docker Compose v2.20+
- 8 GB RAM minimum (16 GB recommended)
- macOS, Linux, or WSL2

### 1. Clone and Configure

```bash
git clone https://github.com/ahmedhassan/apex-os-iam-pam.git
cd apex-os-iam-pam

# Copy environment template
cp .env.example .env

# Generate root certificates (for local dev)
./scripts/generate-certs.sh
```

### 2. Environment Configuration

Edit `.env` with your settings:

```env
# Domain Configuration
APEX_DOMAIN=apex.local
KC_HOSTNAME=keycloak.apex.local
VAULT_ADDR=https://vault.apex.local:8200
POMERIUM_ADDR=https://pomerium.apex.local
TELEPORT_ADDR=https://teleport.apex.local

# Keycloak
KC_ADMIN_USER=admin
KC_ADMIN_PASSWORD=change-me-in-production
KC_DB_PASSWORD=change-me-in-production

# Vault
VAULT_DEV_ROOT_TOKEN=apex-dev-token
VAULT_SEAL_TYPE=awskms  # or shamir for dev

# Teleport
TELEPORT_NODE_TOKEN=change-me-in-production

# OPA
OPA_LOG_LEVEL=debug

# SPIRE
SPIRE_SERVER_DATA_DIR=/var/lib/spire
SPIRE_LOG_LEVEL=INFO
```

### 3. Launch the Stack

```bash
# Start all services
docker-compose up -d

# Verify all services are healthy
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Initialize Vault

```bash
# Initialize Vault (Shamir seal, 5 shares, threshold 3)
docker exec -it apex-os-vault vault operator init

# Unlock Vault with 3 unseal keys
docker exec -it apex-os-vault vault operator unseal <KEY_1>
docker exec -it apex-os-vault vault operator unseal <KEY_2>
docker exec -it apex-os-vault vault operator unseal <KEY_3>

# Login
docker exec -it apex-os-vault vault login <ROOT_TOKEN>
```

### 5. Configure Keycloak

```bash
# Access Keycloak admin console
open https://keycloak.apex.local:8443/admin

# Default credentials: admin / change-me-in-production

# Create a new realm: apex-os
# Configure OIDC client for Pomerium
# Set up MFA policies (TOTP required)
# Configure user federation (LDAP/AD if needed)
```

### 6. Configure Pomerium

```bash
# Edit pomerium/config.yaml
# Set identity provider to Keycloak OIDC
# Define routes and policies

# Reload Pomerium
docker exec apex-os-pomerium pomerium reload
```

### 7. Deploy a Canary Token

```bash
# Access Thinkst Canary console
open https://canary.apex.local

# Create a canary token (e.g., AWS API key, DNS token)
# Place the token in a sensitive location
# Receive instant alert when the token is accessed
```

### 8. Verify the Platform

```bash
# Test SSO through Pomerium
open https://app.apex.local

# Should redirect to Keycloak login
# After authentication, access is granted based on OPA policy

# Test Teleport access
tsh login --proxy=teleport.apex.local
tsh ls
tsh ssh user@target-node

# Test Vault secrets
vault secrets enable -path=apex kv
vault kv put apex/myapp/db password="s3cr3t"
vault kv get apex/myapp/db
```

### Docker Compose Service Map

```yaml
# docker-compose.yml (simplified)
services:
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    ports: ["8443:8443"]
    environment:
      - KC_DB=postgres
      - KC_DB_URL=jdbc:postgresql://keycloak-db:5432/keycloak
      - KC_HOSTNAME=keycloak.apex.local

  vault:
    image: hashicorp/vault:1.15
    ports: ["8200:8200"]
    cap_add: [IPC_LOCK]
    environment:
      - VAULT_DEV_ROOT_TOKEN_ID=apex-dev-token

  pomerium:
    image: pomerium/pomerium:v0.25
    ports: ["443:443"]
    volumes:
      - ./pomerium/config.yaml:/pomerium/config.yaml

  teleport:
    image: public.ecr.aws/gravitational/teleport:15
    ports: ["3022:3022", "3080:3080"]
    volumes:
      - ./teleport/teleport.yaml:/etc/teleport.yaml

  opa:
    image: openpolicyagent/opa:0.60
    ports: ["8181:8181"]
    command: ["run", "--server", "--addr=:8181", "/policies"]

  spire-server:
    image: ghcr.io/spiffe/spire-server:1.8
    ports: ["8081:8081"]
    volumes:
      - ./spire/server.conf:/opt/spire/conf/server/server.conf

  spire-agent:
    image: ghcr.io/spiffe/spire-agent:1.8
    volumes:
      - ./spire/agent.conf:/opt/spire/conf/agent/agent.conf
      - spire-agent-socket:/run/spire/sockets

  canary:
    image: thinkst/canary:latest
    ports: ["8080:8080"]

  keycloak-db:
    image: postgres:16
    environment:
      - POSTGRES_DB=keycloak
      - POSTGRES_USER=keycloak
      - POSTGRES_PASSWORD=change-me-in-production

  vault-db:
    image: postgres:16
    environment:
      - POSTGRES_DB=vault
      - POSTGRES_USER=vault
      - POSTGRES_PASSWORD=change-me-in-production
```

---

## 4. Component Documentation

### 4.1 Keycloak — Identity Provider

**Role:** Central identity provider for SSO, MFA, and user federation.

**Key Configuration:**

```yaml
# keycloak/realm-config.json (excerpt)
{
  "realm": "apex-os",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "resetPasswordAllowed": true,
  "editUsernameAllowed": false,
  "bruteForceProtected": true,
  "permanentLockout": false,
  "maxFailureWaitSeconds": 900,
  "minimumQuickLoginWaitSeconds": 60,
  "waitIncrementSeconds": 60,
  "quickLoginCheckMilliSeconds": 1000,
  "maxDeltaTimeSeconds": 43200,
  "failureFactor": 5,
  "otpPolicyType": "totp",
  "otpPolicyAlgorithm": "HmacSHA1",
  "otpPolicyDigits": 6,
  "otpPolicyPeriod": 30,
  "otpPolicyInitialCounter": 0
}
```

**OIDC Clients:**

| Client | Purpose | Redirect URIs |
|---|---|---|
| `pomerium` | Zero-trust proxy SSO | `https://pomerium.apex.local/oauth2/callback` |
| `teleport` | PAM SSO | `https://teleport.apex.local:3080/v1/webapi/oidc/callback` |
| `vault` | Vault UI login | `https://vault.apex.local:8200/ui/vault/auth/oidc/oidc/callback` |
| `spire` | Workload identity | `https://spire.apex.local/oidc/callback` |

**User Federation:**

- LDAP / Active Directory sync
- Kerberos authentication
- Custom user storage SPI

**MFA Methods:**

- TOTP (Google Authenticator, Authy)
- WebAuthn / FIDO2 (YubiKey, Touch ID)
- Email OTP (fallback)

---

### 4.2 HashiCorp Vault — Secrets Management

**Role:** Central secrets store, dynamic credential generation, PKI, encryption.

**Secret Engines:**

| Engine | Path | Purpose |
|---|---|---|
| KV v2 | `apex/` | Static secrets, key-value storage |
| Database | `database/` | Dynamic database credentials |
| PKI | `pki/` | Internal certificate authority |
| AWS | `aws/` | Dynamic AWS credentials |
| Transit | `transit/` | Encryption as a service |
| Kubernetes | `k8s/` | Service account token management |

**Dynamic Database Credentials:**

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/apex-postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="apex-app,apex-readonly" \
    connection_url="postgresql://{{username}}:{{password}}@postgres.apex.local:5432/apex" \
    username="vault_admin" \
    password="s3cr3t"

# Create role with TTL
vault write database/roles/apex-app \
    db_name=apex-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# Generate credentials
vault read database/creds/apex-app
```

**PKI Configuration:**

```bash
# Enable PKI
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki

# Generate root CA
vault write pki/root/generate/internal \
    common_name="APEX-OS Root CA" \
    ttl=8760h

# Configure intermediate CA
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=4380h pki_int
vault write pki_int/intermediate/generate/internal \
    common_name="APEX-OS Intermediate CA" \
    | tee pki_intermediate.csr
```

**Policies:**

```hcl
# policies/app-read.hcl
path "apex/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "database/creds/apex-app" {
  capabilities = ["read"]
}

path "pki/issue/apex-app" {
  capabilities = ["create", "update"]
}
```

---

### 4.3 OPA / Cedar — Policy Engine

**Role:** Centralized authorization decisions using policy-as-code.

**OPA (Open Policy Agent) Policies:**

```rego
# policies/apex-authz.rego
package apex.authz

import future.keywords.if
import future.keywords.in

default allow := false

# Allow if user has required role for the resource
allow if {
    input.user.roles[_] == required_role
    input.action in allowed_actions
    time.now_ns() < input.user.token_exp
}

# Allow admins to do anything
allow if {
    "admin" in input.user.roles
}

# Allow read-only access during business hours
allow if {
    input.action == "read"
    is_business_hours
}

required_role := "db-admin" if {
    input.resource.type == "database"
}

allowed_actions := ["read", "write", "admin"] if {
    input.resource.type == "database"
}

is_business_hours if {
    [hour, _, _] := time.clock(time.now_ns())
    hour >= 8
    hour <= 18
}
```

**Cedar Policies (AWS-compatible):**

```cedar
// policies/apex-cedar.cedar
permit(
    principal == User::"alice",
    action == Action::"view",
    resource == Photo::"vacation.jpg"
);

permit(
    principal in Group::"engineering",
    action in [Action::"read", Action::"write"],
    resource in Folder::"engineering"
) when {
    resource.owner == principal.id &&
    context.ip.isInRange(ip("10.0.0.0/8"))
};

forbid(
    principal,
    action,
    resource
) when {
    resource.sensitivity == "high" &&
    !context.mfa_verified
};
```

**Integration with Pomerium:**

```yaml
# pomerium/config.yaml (policy excerpt)
policy:
  - from: https://app.apex.local
    to: http://backend:8080
    pass_identity_headers: true
    authorized_users:
      - alice@example.com
    allow:
      or:
        - domain:
            is: example.com
        - claim:
            groups: engineering
```

---

### 4.4 Pomerium — Zero-Trust Proxy

**Role:** Identity-aware reverse proxy enforcing zero-trust access.

**Configuration:**

```yaml
# pomerium/config.yaml
address: ":443"

authenticate:
  idp_provider: keycloak
  idp_client_id: pomerium
  idp_client_secret: ${POMERIUM_CLIENT_SECRET}
  idp_url: https://keycloak.apex.local:8443/realms/apex-os
  redirect_url: https://pomerium.apex.local/oauth2/callback

authorize:
  url: http://opa:8181/v1/data/apex/authz

certificates:
  - cert_file: /etc/pomerium/cert.pem
    key_file: /etc/pomerium/key.pem

routes:
  - from: https://app.apex.local
    to: http://app-backend:8080
    policy:
      - allow:
          or:
            - domain:
                is: example.com
    pass_identity_headers: true
    preserve_host_header: false

  - from: https://api.apex.local
    to: http://api-backend:8081
    policy:
      - allow:
          or:
            - claim:
                groups: api-access
    request_headers:
      X-Apex-User: {{.jwt.sub}}
      X-Apex-Email: {{.jwt.email}}

  - from: https://vault.apex.local
    to: http://vault:8200
    policy:
      - allow:
          or:
            - claim:
                groups: vault-admins
    pass_identity_headers: true

cookie:
  name: _pomerium
  secret: ${POMERIUM_COOKIE_SECRET}
  domain: apex.local
  secure: true
  http_only: true
  same_site: lax
```

**Identity Headers Forwarded:**

| Header | Description |
|---|---|
| `X-Pomerium-Claim-*` | All JWT claims |
| `X-Pomerium-Jwt-Assertion` | Full JWT |
| `X-Forwarded-User` | User ID |
| `X-Forwarded-Email` | User email |
| `X-Forwarded-Groups` | User groups |

---

### 4.5 Teleport — Privileged Access Management

**Role:** Just-in-time privileged access, session recording, audit logging.

**Configuration:**

```yaml
# teleport/teleport.yaml
version: v3
teleport:
  nodename: apex-teleport-01
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO
  ca_pin: "sha256:..."

auth_service:
  enabled: true
  listen_addr: 0.0.0.0:3025
  cluster_name: apex-teleport
  authentication:
    type: oidc
    oidc:
      client_id: teleport
      client_secret: ${TELEPORT_OIDC_SECRET}
      issuer_url: https://keycloak.apex.local:8443/realms/apex-os
      claims_to_roles:
        - claim: groups
          value: teleport-admins
          roles: [admin]
        - claim: groups
          value: teleport-users
          roles: [access]
  authorization:
    mode: local

proxy_service:
  enabled: true
  listen_addr: 0.0.0.0:3023
  web_listen_addr: 0.0.0.0:3080
  public_addr: teleport.apex.local:3080
  https_keypairs:
    - key_file: /etc/teleport/key.pem
      cert_file: /etc/teleport/cert.pem

ssh_service:
  enabled: true
  listen_addr: 0.0.0.0:3022
  commands:
    - name: hostname
      command: [hostname]
    - name: arch
      command: [uname, -p]
  session_recording: node-sync
  enhanced_recording:
    command: true
    network: true

kubernetes_service:
  enabled: true
  listen_addr: 0.0.0.0:3026
  kubeconfig_file: /etc/teleport/kubeconfig

app_service:
  enabled: true
  apps:
    - name: apex-console
      uri: http://localhost:3000
      public_addr: console.apex.local
```

**Access Requests (Just-in-Time):**

```bash
# Request elevated access
tsh request create --roles=db-admin --reason="INCIDENT-1234: Database migration" --reviewers=security-team

# Approve request (as reviewer)
tsh request review <request-id> --approve

# Use the granted access
tsh ssh admin@prod-db-01

# Session is recorded and auditable
tsh play <session-id>
```

**RBAC:**

```yaml
# teleport/roles.yaml
kind: role
version: v7
metadata:
  name: db-admin
spec:
  allow:
    logins: [root, postgres]
    node_labels:
      env: production
      tier: database
    kubernetes_groups: [db-admins]
    kubernetes_labels:
      env: production
    app_labels:
      env: production
    db_names: [apex, analytics]
    db_users: [apex_app]
    request:
      roles: [db-emergency]
  deny: {}
  options:
    format: ssh
    max_session_ttl: 8h0m0s
    port_forwarding: true
    record_session:
      default: best_effort
```

---

### 4.6 Thinkst Canary — Deception Technology

**Role:** Early breach detection through canary tokens and honeypots.

**Canary Token Types:**

| Token Type | Detection Method | Use Case |
|---|---|---|
| `aws-id` | AWS API key used | Cloud credential theft |
| `dns` | DNS lookup triggered | Internal reconnaissance |
| `http` | HTTP request to canary URL | Web app scanning |
| `slack` | Slack webhook called | Slack token theft |
| `git` | Git repo cloned | Source code exfiltration |
| `qr-code` | QR code scanned | Physical security breach |
| `pdf` | PDF opened | Document access tracking |
| `windows-dir` | Directory accessed | File system enumeration |
| `mysql` | DB connection attempted | Database credential theft |

**Deployment:**

```bash
# Deploy canary token (AWS API key)
canarytokengenerator --type aws-id --memo "Production AWS access key" --aws-id AKIA... --aws-secret ...

# Deploy DNS token
canarytokengenerator --type dns --memo "Internal DNS recon" --domain canary.apex.local

# Deploy HTTP token
canarytokengenerator --type http --memo "Web app scan detection" --url https://canary.apex.local/token/abc123
```

**Alert Integration:**

```yaml
# canary/alerts.yaml
alert_channels:
  - type: slack
    webhook_url: ${SLACK_WEBHOOK_URL}
    channel: "#security-alerts"

  - type: email
    smtp_host: smtp.apex.local
    smtp_port: 587
    from: canary@apex.local
    to: security-team@apex.local

  - type: webhook
    url: https://vault.apex.local:8200/v1/apex/alerts
    token: ${VAULT_TOKEN}

alert_rules:
  - name: aws-key-used
    token_type: aws-id
    severity: critical
    auto_disable: true
    notify: [slack, email]

  - name: dns-recon
    token_type: dns
    severity: high
    auto_disable: false
    notify: [slack]
```

---

### 4.7 SPIFFE / SPIRE — Workload Identity

**Role:** Cryptographic workload identity for mTLS everywhere.

**SPIRE Server Configuration:**

```hcl
# spire/server.conf
server {
    bind_address = "0.0.0.0"
    bind_port = "8081"
    socket_path = "/tmp/spire-server/private/api.sock"
    trust_domain = "apex.local"
    data_dir = "/var/lib/spire"
    log_level = "INFO"

    ca_key_type = "ec-p256"
    ca_subject = {
        country = ["US"]
        organization = ["APEX-OS"]
        common_name = "APEX-OS Root CA"
    }
    default_svid_ttl = "1h"
    ca_ttl = "24h"

    jwt_issuer = "https://spire.apex.local"

    plugins {
        NodeAttestor {
            plugin_data {
                join_token {
                    ttl = "600"
                }
            }
        }
        KeyManager {
            plugin_data {
                disk {
                    keys_path = "/var/lib/spire/keys.json"
                }
            }
        }
        DataStore {
            plugin_data {
                sql {
                    database_type = "postgres"
                    connection_string = "postgres://spire:password@spire-db:5432/spire"
                }
            }
        }
        Notifier {
            plugin_data {
                k8sbundle {
                    namespace = "spire"
                    config_map = "spire-bundle"
                    config_map_key = "bundle.crt"
                }
            }
        }
    }
}
```

**SPIRE Agent Configuration:**

```hcl
# spire/agent.conf
agent {
    data_dir = "/var/lib/spire/agent"
    log_level = "INFO"
    server_address = "spire-server"
    server_port = "8081"
    socket_path = "/run/spire/sockets/agent.sock"
    trust_domain = "apex.local"
    trust_bundle_path = "/var/lib/spire/agent/bundle.crt"
    join_token = "${SPIRE_JOIN_TOKEN}"

    plugins {
        NodeAttestor {
            plugin_data {
                join_token {}
            }
        }
        KeyManager {
            plugin_data {
                memory {
                    key_path = "/var/lib/spire/agent/svid.key"
                    cert_path = "/var/lib/spire/agent/svid.crt"
                }
            }
        }
        WorkloadAttestor {
            plugin_data {
                unix {}
                k8s {
                    skip_kubelet_verification = true
                }
            }
        }
    }
}
```

**Workload Registration:**

```bash
# Register a Kubernetes workload
spire-server entry create \
    -spiffeID spiffe://apex.local/ns/apex/sa/my-app \
    -selector k8s:ns:apex \
    -selector k8s:sa:my-app \
    -selector k8s:container-image:my-app:latest \
    -dns my-app.apex.local \
    -ttl 3600

# Register a VM workload
spire-server entry create \
    -spiffeID spiffe://apex.local/host/prod-web-01 \
    -selector unix:uid:1001 \
    -selector unix:path:/opt/myapp/bin/server \
    -dns prod-web-01.apex.local \
    -ttl 3600
```

**Workload API Usage (Go):**

```go
package main

import (
    "context"
    "crypto/tls"
    "crypto/x509"
    "fmt"
    "log"

    "github.com/spiffe/go-spiffe/v2/spiffeid"
    "github.com/spiffe/go-spiffe/v2/workloadapi"
)

func main() {
    ctx := context.Background()

    // Connect to Workload API
    x509Source, err := workloadapi.NewX509Source(ctx,
        workloadapi.WithClientOptions(
            workloadapi.WithAddr("unix:///run/spire/sockets/agent.sock"),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer x509Source.Close()

    // Get X.509 SVID
    svid, err := x509Source.GetX509SVID()
    if err != nil {
        log.Fatal(err)
    }

    fmt.Printf("SPIFFE ID: %s\n", svid.ID)
    fmt.Printf("Certificate expires: %s\n", svid.Certificates[0].NotAfter)

    // Create mTLS config
    tlsConfig := &tls.Config{
        Certificates: []tls.Certificate{svid.X509KeyPair()},
        RootCAs:      x509Source.BundlePool(),
    }

    // Use tlsConfig for gRPC/HTTP client
    _ = tlsConfig
}
```

---

## 5. API Reference

### 5.1 Keycloak API

**Base URL:** `https://keycloak.apex.local:8443`

| Endpoint | Method | Description |
|---|---|---|
| `/realms/apex-os/protocol/openid-connect/token` | POST | Obtain access token |
| `/realms/apex-os/protocol/openid-connect/userinfo` | GET | Get user info |
| `/realms/apex-os/protocol/openid-connect/logout` | POST | Logout |
| `/admin/realms/apex-os/users` | GET/POST | List/create users |
| `/admin/realms/apex-os/users/{id}` | GET/PUT/DELETE | Manage user |
| `/admin/realms/apex-os/groups` | GET/POST | List/create groups |
| `/admin/realms/apex-os/roles` | GET/POST | List/create roles |
| `/admin/realms/apex-os/clients` | GET/POST | List/create clients |
| `/admin/realms/apex-os/identity-provider/instances` | GET/POST | Manage IdPs |

**Example — Get Token:**

```bash
curl -s -X POST \
  https://keycloak.apex.local:8443/realms/apex-os/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=pomerium" \
  -d "client_secret=${POMERIUM_CLIENT_SECRET}" \
  -d "username=alice@example.com" \
  -d "password=..." \
  -d "scope=openid profile email groups" | jq .
```

**Response:**

```json
{
  "access_token": "eyJhbGciOi...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOi...",
  "token_type": "Bearer",
  "not-before-policy": 0,
  "session_state": "..."
}
```

---

### 5.2 Vault API

**Base URL:** `https://vault.apex.local:8200`

| Endpoint | Method | Description |
|---|---|---|
| `/v1/sys/health` | GET | Health check |
| `/v1/sys/seal-status` | GET | Seal status |
| `/v1/auth/token/lookup-self` | GET | Token info |
| `/v1/apex/data/myapp/config` | GET | Read KV secret |
| `/v1/apex/data/myapp/config` | POST | Write KV secret |
| `/v1/database/creds/apex-app` | GET | Generate DB credentials |
| `/v1/pki/issue/apex-app` | POST | Issue certificate |
| `/v1/transit/encrypt/apex-key` | POST | Encrypt data |
| `/v1/transit/decrypt/apex-key` | POST | Decrypt data |
| `/v1/sys/mounts` | GET | List secret engines |
| `/v1/sys/policies/acl` | GET | List policies |

**Example — Read Secret:**

```bash
curl -s \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  https://vault.apex.local:8200/v1/apex/data/myapp/db | jq .
```

**Response:**

```json
{
  "request_id": "...",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "data": {
      "password": "s3cr3t",
      "username": "myapp_user"
    },
    "metadata": {
      "created_time": "2024-01-15T10:30:00Z",
      "custom_metadata": null,
      "deletion_time": "",
      "destroyed": false,
      "version": 1
    }
  }
}
```

**Example — Generate DB Credentials:**

```bash
curl -s \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  https://vault.apex.local:8200/v1/database/creds/apex-app | jq .
```

**Response:**

```json
{
  "request_id": "...",
  "lease_id": "database/creds/apex-app/abc123",
  "renewable": true,
  "lease_duration": 3600,
  "data": {
    "username": "v-apex-app-abc123",
    "password": "aBcDeFgHiJkLmNoP"
  },
  "warnings": null
}
```

---

### 5.3 OPA API

**Base URL:** `http://opa:8181`

| Endpoint | Method | Description |
|---|---|---|
| `/v1/data/apex/authz` | GET | Evaluate policy |
| `/v1/data/apex/authz` | POST | Evaluate with input |
| `/v1/policies` | GET | List policies |
| `/v1/policies/{id}` | GET/PUT/DELETE | Manage policy |
| `/v1/health` | GET | Health check |

**Example — Evaluate Policy:**

```bash
curl -s -X POST \
  http://opa:8181/v1/data/apex/authz \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "user": {
        "id": "alice",
        "roles": ["db-admin"],
        "token_exp": 1893456000
      },
      "resource": {
        "type": "database",
        "name": "prod-db-01"
      },
      "action": "read"
    }
  }' | jq .
```

**Response:**

```json
{
  "result": {
    "allow": true
  }
}
```

---

### 5.4 Teleport API

**Base URL:** `https://teleport.apex.local:3080`

| Endpoint | Method | Description |
|---|---|---|
| `/v1/webapi/oidc/login/web` | POST | OIDC login |
| `/v1/webapi/sessions` | POST | Create session |
| `/v1/webapi/sites/{site}/sessions` | GET | List sessions |
| `/v1/webapi/sites/{site}/sessions/{id}` | GET | Get session |
| `/v1/webapi/sites/{site}/nodes` | GET | List nodes |
| `/v1/webapi/sites/{site}/apps` | GET | List apps |
| `/v1/webapi/sites/{site}/kube/servers` | GET | List K8s servers |
| `/v1/webapi/roles` | GET/POST | Manage roles |
| `/v1/webapi/users` | GET/POST | Manage users |
| `/v1/webapi/access-requests` | GET/POST | Manage access requests |

**CLI Commands:**

```bash
# Login
tsh login --proxy=teleport.apex.local --user=alice

# List nodes
tsh ls

# SSH to node
tsh ssh alice@prod-db-01

# Kubernetes access
tsh kube login prod-cluster
tsh kube ls

# Database access
tsh db login --db-user=apex_app --db-name=apex prod-db
tsh db connect prod-db

# App access
tsh apps login apex-console
tsh apps proxy apex-console

# Request access
tsh request create --roles=db-admin --reason="INCIDENT-1234"

# Play session recording
tsh play <session-id>

# Audit log
tsh audit events --from=2024-01-01 --to=2024-01-31
```

---

### 5.5 SPIRE API

**Base URL:** `http://spire-server:8081`

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/entry` | GET/POST | List/create entries |
| `/api/v1/entry/{id}` | GET/PUT/DELETE | Manage entry |
| `/api/v1/bundle` | GET | Get trust bundle |
| `/api/v1/svid` | POST | Mint SVID |
| `/api/v1/healthcheck` | GET | Health check |

**CLI Commands:**

```bash
# Register entry
spire-server entry create \
    -spiffeID spiffe://apex.local/ns/apex/sa/my-app \
    -selector k8s:ns:apex \
    -selector k8s:sa:my-app

# List entries
spire-server entry show

# Validate SVID
spire-server validate

# Agent commands
spire-agent healthcheck
spire-agent fetch x509
```

---

### 5.6 Pomerium API

**Base URL:** `https://pomerium.apex.local`

| Endpoint | Method | Description |
|---|---|---|
| `/.pomerium/` | GET | Health/status |
| `/oauth2/callback` | GET | OIDC callback |
| `/api/v0/routes` | GET | List routes |
| `/api/v0/policies` | GET | List policies |
| `/api/v0/sessions` | GET | List sessions |

---

## 6. Deployment Guide

### 6.1 Development Deployment

```bash
# Single-node docker-compose deployment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Access services
open https://keycloak.apex.local:8443   # Keycloak admin
open https://vault.apex.local:8200     # Vault UI
open https://pomerium.apex.local       # Pomerium proxy
open https://teleport.apex.local:3080   # Teleport web UI
open https://canary.apex.local:8080     # Canary console
```

### 6.2 Production Deployment

#### Kubernetes Deployment

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: apex-os
  labels:
    app.kubernetes.io/name: apex-os
    app.kubernetes.io/component: security
```

```yaml
# k8s/keycloak/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: apex-os
spec:
  replicas: 3
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:24.0
          args: ["start", "--optimized"]
          ports:
            - containerPort: 8443
              name: https
            - containerPort: 8080
              name: http
          env:
            - name: KC_DB
              value: postgres
            - name: KC_DB_URL
              value: jdbc:postgresql://keycloak-db:5432/keycloak
            - name: KC_DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: keycloak-db
                  key: username
            - name: KC_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-db
                  key: password
            - name: KC_HOSTNAME
              value: keycloak.apex.local
            - name: KC_HTTPS_CERTIFICATE_FILE
              value: /etc/keycloak/tls/tls.crt
            - name: KC_HTTPS_CERTIFICATE_KEY_FILE
              value: /etc/keycloak/tls/tls.key
            - name: KEYCLOAK_ADMIN
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: username
            - name: KEYCLOAK_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: password
          volumeMounts:
            - name: tls
              mountPath: /etc/keycloak/tls
              readOnly: true
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 2000m
              memory: 4Gi
          livenessProbe:
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
      volumes:
        - name: tls
          secret:
            secretName: keycloak-tls
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: apex-os
spec:
  selector:
    app: keycloak
  ports:
    - port: 8443
      targetPort: 8443
      name: https
    - port: 8080
      targetPort: 8080
      name: http
```

```yaml
# k8s/vault/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: vault
  namespace: apex-os
spec:
  serviceName: vault
  replicas: 3
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      containers:
        - name: vault
          image: hashicorp/vault:1.15
          ports:
            - containerPort: 8200
              name: http
            - containerPort: 8201
              name: cluster
          env:
            - name: VAULT_ADDR
              value: http://127.0.0.1:8200
            - name: VAULT_CLUSTER_ADDR
              value: http://127.0.0.1:8201
            - name: VAULT_SEAL_TYPE
              value: awskms
            - name: VAULT_AWSKMS_SEAL_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: vault-kms
                  key: key-id
          command:
            - vault
            - server
            - -config=/etc/vault/vault.hcl
          volumeMounts:
            - name: config
              mountPath: /etc/vault
            - name: data
              mountPath: /vault/data
          securityContext:
            capabilities:
              add: ["IPC_LOCK"]
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 2Gi
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
```

#### Helm Deployment

```bash
# Add Helm repos
helm repo add keycloak https://codecentric.github.io/helm-charts
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add teleport https://charts.releases.teleport.dev
helm repo add spiffe https://spiffe.github.io/helm-charts-hardened

# Install Keycloak
helm install keycloak keycloak/keycloak \
    --namespace apex-os \
    --set auth.adminUser=admin \
    --set auth.adminPassword=${KC_ADMIN_PASSWORD} \
    --set ingress.hosts[0].host=keycloak.apex.local \
    --set postgresql.enabled=true \
    --set postgresql.auth.password=${KC_DB_PASSWORD}

# Install Vault
helm install vault hashicorp/vault \
    --namespace apex-os \
    --set server.ha.enabled=true \
    --set server.ha.replicas=3 \
    --set server.ha.raft.enabled=true \
    --set server.auditStorage.enabled=true \
    --set server.dataStorage.enabled=true

# Install Teleport
helm install teleport teleport/teleport-cluster \
    --namespace apex-os \
    --set clusterName=apex-teleport \
    --set chartMode=standalone \
    --set proxy.highAvailability.minAvailable=2

# Install SPIRE
helm install spire spiffe/spire \
    --namespace apex-os \
    --set global.spire.trustDomain=apex.local
```

### 6.3 Multi-Region Deployment

```mermaid
graph LR
    subgraph "US-East"
        KC1[Keycloak]
        V1[Vault]
        T1[Teleport]
        S1[SPIRE]
    end

    subgraph "US-West"
        KC2[Keycloak]
        V2[Vault]
        T2[Teleport]
        S2[SPIRE]
    end

    subgraph "EU-Central"
        KC3[Keycloak]
        V3[Vault]
        T3[Teleport]
        S3[SPIRE]
    end

    KC1 <-->|Replication| KC2
    KC2 <-->|Replication| KC3
    V1 <-->|DR Replication| V2
    V2 <-->|DR Replication| V3
    S1 <-->|Federation| S2
    S2 <-->|Federation| S3
```

### 6.4 Monitoring & Observability

```yaml
# monitoring/prometheus.yml
scrape_configs:
  - job_name: keycloak
    metrics_path: /metrics
    static_configs:
      - targets: ["keycloak:8080"]

  - job_name: vault
    metrics_path: /v1/sys/metrics
    params:
      format: [prometheus]
    bearer_token: ${VAULT_TOKEN}
    static_configs:
      - targets: ["vault:8200"]

  - job_name: teleport
    metrics_path: /metrics
    static_configs:
      - targets: ["teleport:3080"]

  - job_name: opa
    metrics_path: /metrics
    static_configs:
      - targets: ["opa:8181"]

  - job_name: spire-server
    metrics_path: /metrics
    static_configs:
      - targets: ["spire-server:8081"]

  - job_name: spire-agent
    metrics_path: /metrics
    static_configs:
      - targets: ["spire-agent:8081"]
```

```json
// monitoring/grafana-dashboard.json (excerpt)
{
  "dashboard": {
    "title": "APEX-OS IAM/PAM",
    "panels": [
      {
        "title": "Authentication Rate",
        "targets": [
          {
            "expr": "rate(keycloak_logins_total[5m])"
          }
        ]
      },
      {
        "title": "Failed Login Attempts",
        "targets": [
          {
            "expr": "rate(keycloak_login_failures_total[5m])"
          }
        ]
      },
      {
        "title": "Vault Secret Operations",
        "targets": [
          {
            "expr": "rate(vault_secret_lease_count[5m])"
          }
        ]
      },
      {
        "title": "Teleport Active Sessions",
        "targets": [
          {
            "expr": "teleport_sessions_active"
          }
        ]
      },
      {
        "title": "OPA Policy Evaluation Latency",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, rate(opa_policy_eval_duration_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Canary Token Alerts",
        "targets": [
          {
            "expr": "canary_token_hits_total"
          }
        ]
      }
    ]
  }
}
```

### 6.5 Backup & Disaster Recovery

```bash
#!/bin/bash
# scripts/backup.sh

BACKUP_DIR="/backup/apex-os/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup Vault
vault operator raft snapshot save "$BACKUP_DIR/vault-raft.snap"

# Backup Keycloak DB
kubectl exec -n apex-os keycloak-db-0 -- \
    pg_dump -U keycloak keycloak > "$BACKUP_DIR/keycloak-db.sql"

# Backup Teleport
tsh audit events --from=2020-01-01 > "$BACKUP_DIR/teleport-audit.json"

# Backup SPIRE
kubectl exec -n apex-os spire-server-0 -- \
    spire-server backup > "$BACKUP_DIR/spire-backup.json"

# Backup OPA policies
kubectl exec -n apex-os opa-0 -- \
    tar czf - /policies > "$BACKUP_DIR/opa-policies.tar.gz"

# Encrypt backup
gpg --symmetric --cipher-algo AES256 "$BACKUP_DIR"

# Upload to S3
aws s3 sync "$BACKUP_DIR" s3://apex-os-backups/$(basename "$BACKUP_DIR")

echo "Backup complete: $BACKUP_DIR"
```

---

## 7. Security Considerations

### 7.1 Network Security

- **mTLS everywhere** — All inter-service communication uses mutual TLS via SPIFFE/SPIRE
- **Network segmentation** — Each component runs in its own network segment with strict ingress/egress rules
- **No direct access** — All user access goes through Pomerium or Teleport; no direct service exposure
- **WAF** — Pomerium acts as a web application firewall with rate limiting and bot detection

### 7.2 Secrets Management

- **No hardcoded secrets** — All secrets stored in Vault, injected at runtime
- **Dynamic secrets** — Database, cloud, and API credentials are short-lived and auto-rotated
- **Encryption at rest** — All data encrypted using Vault's transit engine
- **Encryption in transit** — TLS 1.3 for all connections
- **Secret rotation** — Automated rotation policies for all credential types

### 7.3 Access Control

- **Least privilege** — Users and workloads receive minimum necessary permissions
- **Just-in-time access** — Privileged access requires approval and auto-expires
- **Separation of duties** — No single user can approve their own access requests
- **Regular access reviews** — Quarterly access certification campaigns

### 7.4 Audit & Compliance

- **Immutable audit logs** — All events written to append-only storage
- **Session recording** — All privileged sessions recorded and searchable
- **Real-time alerting** — Anomalous access patterns trigger immediate alerts
- **Compliance reporting** — Pre-built reports for SOC 2, HIPAA, PCI-DSS, FedRAMP

### 7.5 Threat Detection

- **Canary tokens** — Deployed across infrastructure for early breach detection
- **Honeypots** — Decoy services that alert on any interaction
- **UEBA** — User and Entity Behavior Analytics for anomaly detection
- **SIEM integration** — All logs forwarded to SIEM (Splunk, ELK, Datadog)

### 7.6 Hardening Checklist

- [ ] Change all default credentials
- [ ] Enable MFA for all user accounts
- [ ] Configure Vault auto-unseal with cloud KMS
- [ ] Enable Teleport session recording
- [ ] Deploy canary tokens in all environments
- [ ] Configure OPA policies for all routes
- [ ] Enable SPIFFE mTLS for all service-to-service communication
- [ ] Set up log aggregation and alerting
- [ ] Configure backup and disaster recovery
- [ ] Run vulnerability scans on all container images
- [ ] Enable network policies (Kubernetes) or security groups (cloud)
- [ ] Configure rate limiting on all public endpoints
- [ ] Set up certificate rotation automation
- [ ] Enable audit logging on all components
- [ ] Conduct regular penetration testing

### 7.7 Incident Response

```mermaid
flowchart TD
    DETECT[Alert Triggered] --> TRIAGE[Triage & Classify]
    TRIAGE -->|Canary Token| CANARY[Identify Compromised Credential]
    TRIAGE -->|Failed Logins| BRUTE[Identify Source IP]
    TRIAGE -->|Anomalous Access| UEBA[Identify Compromised Account]

    CANARY --> REVOKE[Revoke Credential in Vault]
    BRUTE --> BLOCK[Block IP in Pomerium]
    UEBA --> SUSPEND[Suspend User in Keycloak]

    REVOKE --> INVESTIGATE[Forensic Investigation]
    BLOCK --> INVESTIGATE
    SUSPEND --> INVESTIGATE

    INVESTIGATE --> EVIDENCE[Collect Evidence]
    EVIDENCE --> REMEDIATE[Remediate]
    REMEDIATE --> POSTINCIDENT[Post-Incident Review]
    POSTINCIDENT --> IMPROVE[Update Policies & Controls]
```

---

## 8. License

```
APEX-OS IAM/PAM
Copyright (C) 2024 Ahmed Hassan

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

### AGPL-3.0 Summary

| Permission | Condition | Limitation |
|---|---|---|
| ✅ Commercial use | 📋 License and copyright notice | ❌ Liability |
| ✅ Distribution | 📋 State changes | ❌ Warranty |
| ✅ Modification | 📋 Disclose source | |
| ✅ Patent use | 📋 Network use is distribution | |
| ✅ Private use | 📋 Same license | |

> **Note:** The AGPL-3.0 license requires that if you modify APEX-OS IAM/PAM and make it available over a network, you must make the source code of your modified version available to users under the same license.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to APEX-OS IAM/PAM.

## Support

- **Documentation:** https://github.com/AAH20/apex-os-iam-pam/wiki
- **Issues:** https://github.com/AAH20/apex-os-iam-pam/issues
- **Discussions:** https://github.com/AAH20/apex-os-iam-pam/discussions
- **Security:** aah@a2zsoc.com

---

*Built with 🔐 by Ahmed Hassan and contributors.*
