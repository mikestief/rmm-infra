# RMM Infrastructure

Terraform configuration for RMM (Rusty Maintenance Man) infrastructure on Google Cloud Platform.

## Infrastructure Components

### Compute (Cloud Run)
- **rmm-ui-service**: Frontend + BFF (Express).
- **rmm-vehicle-api-service**: Private backend service.
- **rmm-places-api-service**: Private backend service.

### Networking
- **Global External Load Balancer**: Handles SSL Termination and routes traffic to the UI service.
- **VPC Network**: Enables serverless VPC access and private service access for Cloud SQL.

### Database
- **Cloud SQL (PostgreSQL)**: Private IP only, utilizing IAM Authentication for secure access.

## Security Implementation

- **IAM Authentication**: All services use IAM for authentication, eliminating the need for passwords.
- **Network Isolation**: Backend APIs and databases are not accessible from the public internet; traffic is routed through a secure VPC.
- **Secret Management**: Sensitive information is managed via Google Secret Manager.

## Coding Standards

- **Consistency**: Run `terraform fmt` before committing to ensure consistent HCL styling.
- **Naming**: Use meaningful and descriptive resource names.
- **State Management**: Remote state is used for all production resources; never commit state files or execution plans.

## Usage & Development

### Local Review
1. Initialize Terraform:
   ```bash
   terraform init
   ```
2. Review the plan:
   ```bash
   terraform plan
   ```

## Deployment

Infrastructure changes are managed and deployed through the project's automated deployment actions (CI/CD). Manual `gcloud` or `terraform apply` operations are deprecated for production changes.
