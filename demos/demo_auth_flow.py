#!/usr/bin/env python3
"""
APEX-OS IAM/PAM — Authentication Flow Demo
===========================================

Demonstrates the full authentication lifecycle across three core components:

  1. Keycloak  — Identity Provider (IdP): issues OIDC tokens
  2. Vault     — Secrets Engine: stores and serves credentials
  3. OPA       — Policy Engine: enforces access decisions

Flow:
  Step 1: User authenticates with Keycloak → receives JWT
  Step 2: JWT is validated (signature, expiry, issuer)
  Step 3: OPA evaluates access policy against the JWT claims
  Step 4: On allow, Vault mints a short-lived database credential
  Step 5: Credential is used and revoked

Run:
  python3 demo_auth_flow.py
"""

from __future__ import annotations

import json
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

# ─── Colour helpers ──────────────────────────────────────────────────────────

class Colour:
    """ANSI colour codes for terminal output."""
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
    """Wrap text in ANSI colour codes."""
    return "".join(codes) + text + Colour.RESET

def banner(text: str) -> None:
    """Print a section banner."""
    width = 64
    print()
    print(c("═" * width, Colour.BOLD, Colour.CYAN))
    print(c(f"  {text}", Colour.BOLD, Colour.CYAN))
    print(c("═" * width, Colour.BOLD, Colour.CYAN))

def step(num: int, title: str) -> None:
    """Print a step header."""
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

@dataclass
class OIDCClaims:
    """Parsed JWT claims (simplified)."""
    sub: str
    iss: str
    aud: str
    exp: int
    iat: int
    preferred_username: str
    email: str
    groups: List[str] = field(default_factory=list)
    scope: str = ""

@dataclass
class VaultCredential:
    """A credential minted by Vault."""
    request_id: str
    lease_id: str
    data: Dict[str, Any]
    lease_duration: int
    renewable: bool
    expire_time: datetime


# ─── Component: Keycloak (IdP) ────────────────────────────────────────────────

class Keycloak:
    """Simulated Keycloak identity provider."""

    def __init__(self, realm: str = "apex-os") -> None:
        self.realm = realm
        self._users: Dict[str, Dict[str, str]] = {
            "alice": {"password": "alice-pass-123", "email": "aah@a2zsoc.com",
                       "groups": ["developers", "oncall"]},
            "bob":   {"password": "bob-pass-456",   "email": "aah@a2zsoc.com",
                       "groups": ["auditors"]},
        }
        self._tokens: Dict[str, OIDCClaims] = {}

    def authenticate(self, username: str, password: str) -> Optional[str]:
        """Authenticate a user and return a JWT (simulated)."""
        user = self._users.get(username)
        if not user or user["password"] != password:
            return None

        now = int(time.time())
        claims = OIDCClaims(
            sub=str(uuid.uuid4()),
            iss=f"http://localhost:8080/realms/{self.realm}",
            aud="apex-os-cli",
            exp=now + 300,
            iat=now,
            preferred_username=username,
            email=user["email"],
            groups=user["groups"],
            scope="openid profile email groups",
        )
        token = self._encode_jwt(claims)
        self._tokens[token] = claims
        return token

    def validate_token(self, token: str) -> Optional[OIDCClaims]:
        """Validate a JWT: signature, expiry, issuer."""
        claims = self._tokens.get(token)
        if not claims:
            return None
        if claims.exp < int(time.time()):
            return None
        if not claims.iss.startswith("http://localhost:8080"):
            return None
        return claims

    @staticmethod
    def _encode_jwt(claims: OIDCClaims) -> str:
        """Simulate JWT encoding (header.payload.signature)."""
        import base64
        header = base64.urlsafe_b64encode(
            json.dumps({"alg": "RS256", "typ": "JWT"}).encode()
        ).decode().rstrip("=")
        payload = base64.urlsafe_b64encode(
            json.dumps({
                "sub": claims.sub,
                "iss": claims.iss,
                "aud": claims.aud,
                "exp": claims.exp,
                "iat": claims.iat,
                "preferred_username": claims.preferred_username,
                "email": claims.email,
                "groups": claims.groups,
                "scope": claims.scope,
            }).encode()
        ).decode().rstrip("=")
        signature = base64.urlsafe_b64encode(
            uuid.uuid4().bytes + uuid.uuid4().bytes
        ).decode().rstrip("=")
        return f"{header}.{payload}.{signature}"


# ─── Component: OPA (Policy Engine) ──────────────────────────────────────────

class OPA:
    """Simulated Open Policy Agent."""

    def __init__(self) -> None:
        self._policies: Dict[str, Dict[str, Any]] = {
            "db-read": {
                "description": "Allow read access to production DB for developers",
                "allowed_groups": ["developers"],
                "allowed_actions": ["SELECT"],
                "effect": "allow",
            },
            "db-admin": {
                "description": "Allow admin access for oncall engineers",
                "allowed_groups": ["oncall"],
                "allowed_actions": ["SELECT", "INSERT", "UPDATE", "DELETE"],
                "effect": "allow",
            },
            "audit-read": {
                "description": "Allow auditors read-only access",
                "allowed_groups": ["auditors"],
                "allowed_actions": ["SELECT"],
                "effect": "allow",
            },
        }

    def evaluate(self, claims: OIDCClaims, policy_name: str,
                 action: str, resource: str) -> Dict[str, Any]:
        """Evaluate a policy against JWT claims."""
        policy = self._policies.get(policy_name)
        if not policy:
            return {"allow": False, "reason": f"Policy '{policy_name}' not found"}

        if policy["effect"] != "allow":
            return {"allow": False, "reason": "Policy effect is 'deny'"}

        if action not in policy["allowed_actions"]:
            return {
                "allow": False,
                "reason": f"Action '{action}' not permitted by policy",
            }

        user_groups = set(claims.groups)
        allowed_groups = set(policy["allowed_groups"])
        if not user_groups & allowed_groups:
            return {
                "allow": False,
                "reason": (
                    f"User groups {sorted(user_groups)} do not intersect "
                    f"with allowed groups {sorted(allowed_groups)}"
                ),
            }

        return {
            "allow": True,
            "reason": (
                f"User '{claims.preferred_username}' in groups "
                f"{sorted(user_groups & allowed_groups)} is permitted "
                f"to {action} on {resource}"
            ),
        }


# ─── Component: Vault (Secrets Engine) ───────────────────────────────────────

class Vault:
    """Simulated HashiCorp Vault."""

    def __init__(self) -> None:
        self._credentials: Dict[str, VaultCredential] = {}
        self._lease_counter = 0

    def mint_database_credential(
        self,
        claims: OIDCClaims,
        database: str,
        ttl: int = 300,
    ) -> VaultCredential:
        """Mint a short-lived database credential."""
        self._lease_counter += 1
        username = f"vault-{claims.preferred_username}-{self._lease_counter}"
        password = str(uuid.uuid4())[:16]

        cred = VaultCredential(
            request_id=str(uuid.uuid4()),
            lease_id=f"database/creds/{database}/{uuid.uuid4().hex[:12]}",
            data={"username": username, "password": password},
            lease_duration=ttl,
            renewable=True,
            expire_time=datetime.now(timezone.utc) + timedelta(seconds=ttl),
        )
        self._credentials[cred.lease_id] = cred
        return cred

    def revoke_lease(self, lease_id: str) -> bool:
        """Revoke a lease immediately."""
        return self._credentials.pop(lease_id, None) is not None

    def renew_lease(self, lease_id: str, increment: int = 300) -> Optional[datetime]:
        """Renew a lease by the given increment."""
        cred = self._credentials.get(lease_id)
        if not cred or not cred.renewable:
            return None
        cred.expire_time += timedelta(seconds=increment)
        return cred.expire_time


# ─── Demo runner ──────────────────────────────────────────────────────────────

def run_demo() -> None:
    """Execute the full authentication flow demo."""

    banner("APEX-OS IAM/PAM — Authentication Flow Demo")
    print()
    info("Components: Keycloak (IdP) · Vault (Secrets) · OPA (Policy)")

    # ── Step 1: User authenticates with Keycloak ──────────────────────────────
    step(1, "User Authentication via Keycloak")

    kc = Keycloak(realm="apex-os")
    username = "alice"
    password = "alice-pass-123"

    info(f"Authenticating user '{username}' against Keycloak realm 'apex-os'…")
    token = kc.authenticate(username, password)

    if token:
        ok(f"Authentication successful — JWT issued")
        parts = token.split(".")
        kv("JWT header",  f"{parts[0][:40]}…")
        kv("JWT payload", f"{parts[1][:40]}…")
        kv("JWT signature", f"{parts[2][:40]}…")
    else:
        fail("Authentication failed — invalid credentials")
        return

    # ── Step 2: Token validation ─────────────────────────────────────────────
    step(2, "JWT Validation")

    claims = kc.validate_token(token)
    if claims:
        ok("Token is valid (signature, expiry, issuer all verified)")
        kv("Subject", claims.sub[:16] + "…")
        kv("Issuer", claims.iss)
        kv("Username", claims.preferred_username)
        kv("Email", claims.email)
        kv("Groups", ", ".join(claims.groups))
        kv("Expires", datetime.fromtimestamp(claims.exp, tz=timezone.utc).isoformat())
    else:
        fail("Token validation failed")
        return

    # ── Step 3: OPA policy evaluation ────────────────────────────────────────
    step(3, "OPA Policy Evaluation")

    opa = OPA()
    policy_name = "db-read"
    action = "SELECT"
    resource = "production-db"

    info(f"Evaluating policy '{policy_name}' for action '{action}' on '{resource}'…")
    decision = opa.evaluate(claims, policy_name, action, resource)

    if decision["allow"]:
        ok(f"Access GRANTED — {decision['reason']}")
    else:
        fail(f"Access DENIED — {decision['reason']}")
        return

    # Also show a denied case
    info("Now evaluating a denied case (bob, auditors group, DELETE)…")
    bob_token = kc.authenticate("bob", "bob-pass-456")
    bob_claims = kc.validate_token(bob_token) if bob_token else None
    if bob_claims:
        deny_decision = opa.evaluate(bob_claims, "db-read", "DELETE", "production-db")
        if not deny_decision["allow"]:
            fail(f"Access DENIED — {deny_decision['reason']}")

    # ── Step 4: Vault mints a database credential ────────────────────────────
    step(4, "Vault — Dynamic Database Credential")

    vault = Vault()
    cred = vault.mint_database_credential(claims, database="production-db", ttl=300)

    ok("Vault minted a short-lived database credential")
    kv("Lease ID", cred.lease_id)
    kv("Username", cred.data["username"])
    kv("Password", cred.data["password"])
    kv("TTL", f"{cred.lease_duration}s")
    kv("Renewable", str(cred.renewable))
    kv("Expires at", cred.expire_time.isoformat())

    # ── Step 5: Credential usage and revocation ──────────────────────────────
    step(5, "Credential Lifecycle — Use, Renew, Revoke")

    info("Using credential to connect to production-db…")
    ok(f"Connected as '{cred.data['username']}' — executed: SELECT * FROM users LIMIT 1")

    info("Renewing lease by 300s…")
    new_expiry = vault.renew_lease(cred.lease_id, increment=300)
    if new_expiry:
        ok(f"Lease renewed — new expiry: {new_expiry.isoformat()}")

    info("Revoking lease (simulating session end)…")
    if vault.revoke_lease(cred.lease_id):
        ok("Lease revoked — credential is no longer valid")
    else:
        fail("Lease revocation failed")

    # ── Summary ──────────────────────────────────────────────────────────────
    banner("Summary")
    print()
    ok("Keycloak issued a valid JWT for 'alice'")
    ok("OPA granted SELECT on production-db based on group membership")
    ok("Vault minted a short-lived, renewable database credential")
    ok("Lease was renewed and then revoked — full lifecycle complete")
    print()
    info("This demonstrates APEX-OS IAM/PAM's core auth flow:")
    info("  Identity (Keycloak) → Policy (OPA) → Secrets (Vault) → Audit")
    print()


if __name__ == "__main__":
    run_demo()
