# CLAUDE.md — rmm-infra

Terraform infrastructure-as-code for the entire RMM GCP ecosystem. See parent `CLAUDE.md` for full system architecture and branching policy.

## Tech Stack

- **IaC:** Terraform v1.0+
- **Cloud:** GCP project `rustymaintenance`, region `us-central1`

## Key Files

| File | Manages |
|------|---------|
| `main.tf` | Provider config |
| `cloud-run-ingress.tf` | Cloud Run services, load balancer, SSL |
| `cloud-sql.tf` / `cloud-sql-database.tf` | PostgreSQL instances |
| `iam.tf` | Service accounts, IAM roles |
| `load-balancer.tf` | Global External Load Balancer routing |
| `apis.tf` | GCP API enablement |
| `storage.tf` | GCS buckets |
| `scheduler.tf` | Cloud Scheduler (maintenance reminders) |
| `monitoring.tf` | Cloud Trace, logging |

## Development Workflow

```bash
terraform fmt -recursive   # format before every commit
terraform validate         # validate config
terraform plan             # preview changes — safe, never modifies state
```

Always run `terraform fmt` and `terraform validate` before committing.

## Rules

- **NEVER** run `terraform apply` or `terraform destroy` without explicit user confirmation
- **NEVER** commit `.tfstate` files or execution plans to version control — state is remote
- Use meaningful resource names
- Run `terraform fmt -recursive` before every commit
- All PRs must pass `terraform validate` and `terraform plan` cleanly

## When to Change This Repo

Changes here are required when any other repo needs:
- New or updated Cloud Run environment variables
- New GCS buckets or IAM permissions
- New secrets in Secret Manager
- New Cloud Run services or load balancer routing changes
- New Cloud Scheduler jobs
- Changes to VPC, networking, or Cloud SQL config
