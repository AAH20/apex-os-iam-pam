# APEX-OS IAM/PAM — Terraform Modules

Comprehensive Terraform modules for identity and access management across AWS, Azure, GCP, Kubernetes, with monitoring and security group management.

## Architecture

```
terraform/
├── main.tf                          # Root module orchestrator
├── variables.tf                     # Root variables
├── outputs.tf                       # Root outputs
├── terraform.tfvars.example        # Example variable values
├── README.md                        # This file
└── modules/
    ├── aws-iam/                     # AWS IAM module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── azure-iam/                   # Azure IAM module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── gcp-iam/                     # GCP IAM module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── k8s-rbac/                    # Kubernetes RBAC module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── monitoring/                  # Monitoring module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── security-groups/             # Security Groups module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Modules

### AWS IAM (`modules/aws-iam`)
- IAM users, groups, roles, and policies
- MFA enforcement
- Access key management
- Account password policy
- Service Control Policies (SCPs)

### Azure IAM (`modules/azure-iam`)
- Azure AD users and groups
- Custom RBAC role definitions
- Role assignments
- Conditional Access policies
- Privileged Identity Management (PIM)
- Key Vault access policies

### GCP IAM (`modules/gcp-iam`)
- Service accounts and keys
- Custom IAM roles
- Project, organization, and folder-level bindings
- IAM audit configurations
- Essential contacts

### Kubernetes RBAC (`modules/k8s-rbac`)
- Namespaces
- Roles and ClusterRoles
- RoleBindings and ClusterRoleBindings
- ServiceAccounts
- Pod Security Policies
- Network Policies

### Monitoring (`modules/monitoring`)
- AWS CloudWatch (log groups, metric alarms, dashboards, event rules)
- AWS Security Hub and GuardDuty
- Azure Monitor (Log Analytics, action groups, metric/activity alerts)
- GCP Monitoring (alert policies, notification channels, dashboards)

### Security Groups (`modules/security-groups`)
- AWS Security Groups and standalone rules
- Azure NSGs with subnet/NIC associations
- GCP Firewall rules and firewall policies

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Plan:**
   ```bash
   terraform plan
   ```

4. **Apply:**
   ```bash
   terraform apply
   ```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Azure CLI logged in
- GCP CLI authenticated
- Kubernetes cluster access configured

## Security Considerations

- All sensitive values (passwords, tokens) should be managed via a secrets manager
- MFA is enforced by default for AWS IAM users
- Password policies are configured with strong defaults
- All resources are tagged for cost allocation and compliance
- State file is encrypted at rest with DynamoDB locking

## License

Proprietary — APEX-OS Internal Use Only
