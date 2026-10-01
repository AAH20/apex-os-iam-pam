#!/usr/bin/env python3
"""
APEX-OS IAM/PAM — Dynamic Secrets Management Demo
==================================================

Demonstrates HashiCorp Vault's dynamic secrets engine capabilities:

  1. Database Credentials  — short-lived, auto-revoked DB passwords
  2. AWS Credentials      — dynamic IAM keys with configurable TTL
  3. PKI Certificates      — on-demand TLS certificate issuance
  4. Lease Management      — renew, revoke, and lifecycle tracking

Each secret type shows:
  - Creation (minting)
  - Usage simulation
  - Renewal (where applicable)
  - Revocation / expiry

Run:
  python3 demo_secrets_management.py
"""

from __future__ import annotations

import json
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Any, Dict, List, Optional


# ─── Colour helpers ──────────────────────────────────────────────────────────

class Colour:
    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    DIM    = "\033[2m"
    GREEN  = "\033[92m"
    YELLOW = "\033[93m"
    RED    = "\033[91m"
    CYAN   = "\033[96m"
    BLUE   = "\033[94m"
    PURPLE = "\033[95m"

def c(text: str, *codes: str) -> str:
    return "".join(codes) + text + Colour.RESET

def banner(text: str) -> None:
    width = 64
    print()
    print(c("═" * width, Colour.BOLD, Colour.CYAN))
    print(c(f"  {text}", Colour.BOLD, Colour.CYAN))
    print(c("═" * width, Colour.BOLD, Colour.CYAN))

def step(num: int, title: str) -> None:
    print()
    print(c(f"  Step {num}: {title}", Colour.BOLD, Colour.YELLOW))
    print(c("  " + "─" * 56, Colour.DIM))

def ok(msg: str) -> None:
    print(c(f"  ✓ {msg}", Colour.GREEN))

def fail(msg: str) -> None:
    print(c(f"  ✗ {msg}", Colour.RED))

def info(msg: str) -> None:
    print(c(f"  ℹ {msg}", Colour.BLUE))

def kv(key: str, value: Any) -> None:
    print(f"    {c(key + ':', Colour.DIM):<28} {value}")


# ─── Data models ──────────────────────────────────────────────────────────────

class SecretType(Enum):
    DATABASE = "database"
    AWS = "aws"
    PKI = "pki"

@dataclass
class Lease:
    """A Vault lease."""
    lease_id: str
    secret_type: SecretType
    data: Dict[str, Any]
    ttl: int
    created_at: datetime
    expire_at: datetime
    renewable: bool
    revoked: bool = False
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def is_expired(self) -> bool:
        return datetime.now(timezone.utc) >= self.expire_at

    @property
    def remaining(self) -> int:
        remaining = int((self.expire_at - datetime.now(timezone.utc)).total_seconds())
        return max(0, remaining)


# ─── Vault Dynamic Secrets Engine ────────────────────────────────────────────

class VaultSecretsEngine:
    """Simulated Vault dynamic secrets engine."""

    def __init__(self) -> None:
        self._leases: Dict[str, Lease] = {}
        self._lease_counter = 0
        self._audit_log: List[Dict[str, Any]] = []

    def _next_id(self) -> str:
        self._lease_counter += 1
        return f"lease-{self._lease_counter:04d}"

    def _audit(self, action: str, lease_id: str, details: str) -> None:
        self._audit_log.append({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": action,
            "lease_id": lease_id,
            "details": details,
        })

    # ── Database credentials ────────────────────────────────────────────────

    def create_database_credentials(
        self,
        database: str,
        role: str,
        ttl: int = 300,
    ) -> Lease:
        """Mint dynamic database credentials."""
        lease_id = f"database/creds/{role}/{self._next_id()}"
        username = f"v-{role}-{self._lease_counter}-{uuid.uuid4().hex[:6]}"
        password = str(uuid.uuid4())[:20]

        now = datetime.now(timezone.utc)
        lease = Lease(
            lease_id=lease_id,
            secret_type=SecretType.DATABASE,
            data={
                "username": username,
                "password": password,
                "database": database,
                "role": role,
            },
            ttl=ttl,
            created_at=now,
            expire_at=now + timedelta(seconds=ttl),
            renewable=True,
            metadata={"engine": "postgresql", "host": "db.apex-os.io"},
        )
        self._leases[lease_id] = lease
        self._audit("CREATE", lease_id, f"db creds for {database}/{role}")
        return lease

    # ── AWS credentials ─────────────────────────────────────────────────────

    def create_aws_credentials(
        self,
        role: str,
        ttl: int = 600,
        region: str = "us-east-1",
    ) -> Lease:
        """Mint dynamic AWS IAM credentials."""
        lease_id = f"aws/creds/{role}/{self._next_id()}"
        access_key = f"AKIA{uuid.uuid4().hex[:16].upper()}"
        secret_key = uuid.uuid4().hex + uuid.uuid4().hex

        now = datetime.now(timezone.utc)
        lease = Lease(
            lease_id=lease_id,
            secret_type=SecretType.AWS,
            data={
                "access_key_id": access_key,
                "secret_access_key": secret_key[:8] + "…" + secret_key[-4:],
                "region": region,
                "role": role,
            },
            ttl=ttl,
            created_at=now,
            expire_at=now + timedelta(seconds=ttl),
            renewable=True,
            metadata={"sts_role_arn": f"arn:aws:iam::123456789012:role/{role}"},
        )
        self._leases[lease_id] = lease
        self._audit("CREATE", lease_id, f"aws creds for role {role}")
        return lease

    # ── PKI certificates ────────────────────────────────────────────────────

    def create_pki_certificate(
        self,
        common_name: str,
        ttl: int = 3600,
        alt_names: Optional[List[str]] = None,
    ) -> Lease:
        """Issue a PKI certificate."""
        lease_id = f"pki/issue/{common_name.replace('.', '-')}/{self._next_id()}"
        serial = uuid.uuid4().hex[:16].upper()

        now = datetime.now(timezone.utc)
        lease = Lease(
            lease_id=lease_id,
            secret_type=SecretType.PKI,
            data={
                "serial_number": serial,
                "common_name": common_name,
                "alt_names": alt_names or [],
                "certificate": f"-----BEGIN CERTIFICATE-----\n{serial[:32]}…\n-----END CERTIFICATE-----",
                "private_key": f"-----BEGIN RSA PRIVATE KEY-----\n{uuid.uuid4().hex[:32]}…\n-----END RSA PRIVATE KEY-----",
                "issuer": "APEX-OS Root CA",
                "chain": ["APEX-OS Intermediate CA", "APEX-OS Root CA"],
            },
            ttl=ttl,
            created_at=now,
            expire_at=now + timedelta(seconds=ttl),
            renewable=False,
            metadata={"key_type": "rsa", "key_bits": 2048},
        )
        self._leases[lease_id] = lease
        self._audit("CREATE", lease_id, f"pki cert for {common_name}")
        return lease

    # ── Lease management ────────────────────────────────────────────────────

    def renew_lease(self, lease_id: str, increment: int = 300) -> Optional[datetime]:
        """Renew a lease."""
        lease = self._leases.get(lease_id)
        if not lease or not lease.renewable or lease.revoked:
            return None
        lease.expire_at = datetime.now(timezone.utc) + timedelta(seconds=increment)
        self._audit("RENEW", lease_id, f"renewed by {increment}s")
        return lease.expire_at

    def revoke_lease(self, lease_id: str) -> bool:
        """Revoke a lease immediately."""
        lease = self._leases.get(lease_id)
        if not lease or lease.revoked:
            return False
        lease.revoked = True
        self._audit("REVOKE", lease_id, "manually revoked")
        return True

    def revoke_by_prefix(self, prefix: str) -> int:
        """Revoke all leases matching a prefix."""
        count = 0
        for lease in self._leases.values():
            if lease.lease_id.startswith(prefix) and not lease.revoked:
                lease.revoked = True
                self._audit("REVOKE", lease_id=lease.lease_id, details="prefix revocation")
                count += 1
        return count

    def list_leases(self, include_revoked: bool = False) -> List[Lease]:
        """List all leases."""
        leases = self._leases.values()
        if not include_revoked:
            leases = [l for l in leases if not l.revoked]
        return list(leases)

    def get_audit_log(self) -> List[Dict[str, Any]]:
        """Return the audit log."""
        return list(self._audit_log)


# ─── Demo runner ──────────────────────────────────────────────────────────────

def run_demo() -> None:
    """Execute the dynamic secrets management demo."""

    banner("APEX-OS IAM/PAM — Dynamic Secrets Management Demo")
    print()
    info("Engine: HashiCorp Vault (simulated)")
    info("Secret types: Database · AWS · PKI")

    vault = VaultSecretsEngine()

    # ── Step 1: Database credentials ─────────────────────────────────────────
    step(1, "Dynamic Database Credentials")

    info("Creating short-lived credentials for 'production-db' (role: 'app-reader', TTL: 300s)…")
    db_lease = vault.create_database_credentials(
        database="production-db",
        role="app-reader",
        ttl=300,
    )
    ok("Database credentials minted")
    kv("Lease ID", db_lease.lease_id)
    kv("Username", db_lease.data["username"])
    kv("Password", db_lease.data["password"])
    kv("TTL", f"{db_lease.ttl}s")
    kv("Expires at", db_lease.expire_at.strftime("%H:%M:%S"))
    kv("Renewable", str(db_lease.renewable))

    info("Simulating usage: connecting to production-db…")
    ok(f"Connected as '{db_lease.data['username']}' — SELECT * FROM orders LIMIT 10")

    info("Renewing lease by 300s…")
    new_expiry = vault.renew_lease(db_lease.lease_id, increment=300)
    if new_expiry:
        ok(f"Lease renewed — new expiry: {new_expiry.strftime('%H:%M:%S')}")

    # ── Step 2: AWS credentials ──────────────────────────────────────────────
    step(2, "Dynamic AWS Credentials")

    info("Creating AWS STS credentials for role 'deploy-role' (TTL: 600s)…")
    aws_lease = vault.create_aws_credentials(
        role="deploy-role",
        ttl=600,
        region="us-east-1",
    )
    ok("AWS credentials minted")
    kv("Lease ID", aws_lease.lease_id)
    kv("Access Key ID", aws_lease.data["access_key_id"])
    kv("Secret Access Key", aws_lease.data["secret_access_key"])
    kv("Region", aws_lease.data["region"])
    kv("TTL", f"{aws_lease.ttl}s")
    kv("STS Role", aws_lease.metadata["sts_role_arn"])

    info("Simulating usage: deploying to S3…")
    ok(f"aws s3 cp app.tar.gz s3://apex-os-releases/ — success")

    # ── Step 3: PKI certificates ────────────────────────────────────────────
    step(3, "PKI Certificate Issuance")

    info("Issuing TLS certificate for 'api.apex-os.io' (TTL: 3600s)…")
    pki_lease = vault.create_pki_certificate(
        common_name="api.apex-os.io",
        ttl=3600,
        alt_names=["api.apex-os.io", "api.internal.apex-os.io"],
    )
    ok("PKI certificate issued")
    kv("Lease ID", pki_lease.lease_id)
    kv("Serial Number", pki_lease.data["serial_number"])
    kv("Common Name", pki_lease.data["common_name"])
    kv("Alt Names", ", ".join(pki_lease.data["alt_names"]))
    kv("Issuer", pki_lease.data["issuer"])
    kv("TTL", f"{pki_lease.ttl}s")
    kv("Renewable", str(pki_lease.renewable))

    info("Simulating usage: configuring TLS on load balancer…")
    ok("TLS certificate installed on apex-os-lb-01 — HTTPS enabled")

    # ── Step 4: Lease management ─────────────────────────────────────────────
    step(4, "Lease Lifecycle Management")

    info("Listing all active leases…")
    active = vault.list_leases()
    for lease in active:
        status = c("ACTIVE", Colour.GREEN) if not lease.is_expired else c("EXPIRED", Colour.RED)
        kv(
            lease.secret_type.value.upper(),
            f"{lease.lease_id} — {lease.remaining}s remaining [{status}]",
        )

    info("Revoking database lease (simulating session end)…")
    if vault.revoke_lease(db_lease.lease_id):
        ok(f"Lease '{db_lease.lease_id}' revoked")

    info("Revoking all AWS leases by prefix…")
    revoked_count = vault.revoke_by_prefix("aws/creds/")
    ok(f"Revoked {revoked_count} AWS lease(s)")

    # ── Step 5: Audit log ────────────────────────────────────────────────────
    step(5, "Audit Log")

    audit = vault.get_audit_log()
    info(f"Total audit events: {len(audit)}")
    for event in audit:
        action_colour = {
            "CREATE": Colour.GREEN,
            "RENEW":  Colour.YELLOW,
            "REVOKE": Colour.RED,
        }.get(event["action"], Colour.RESET)
        print(
            f"    {c(event['timestamp'][11:19], Colour.DIM)}  "
            f"{c(event['action'], action_colour):<8}  "
            f"{c(event['lease_id'], Colour.DIM):<45}  "
            f"{event['details']}"
        )

    # ── Summary ──────────────────────────────────────────────────────────────
    banner("Summary")
    print()
    ok("Database credentials: created, used, renewed, revoked")
    ok("AWS credentials: created, used, prefix-revoked")
    ok("PKI certificate: issued with SANs, installed on LB")
    ok("Full audit trail captured for all operations")
    print()
    info("Key takeaways:")
    info("  · No static secrets — all credentials are short-lived")
    info("  · Automatic revocation via lease expiry or manual revoke")
    info("  · Every operation is auditable")
    info("  · Different TTLs per secret type and role")
    print()


if __name__ == "__main__":
    run_demo()
