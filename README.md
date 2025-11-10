# RMM Infrastructure

Terraform configuration for RMM (Rusty Maintenance Man) infrastructure on Google Cloud Platform.

## Overview

This repository contains infrastructure-as-code for:
- Global External HTTP(S) Load Balancer
- Cloud Run service ingress configuration
- SSL certificate management
- Network endpoint groups and backend services

## Prerequisites

- Terraform >= 1.0
- Google Cloud SDK (gcloud) installed and configured
- Access to GCP project: `rustymaintenance`
- Appropriate IAM permissions to create load balancer resources and manage Cloud Run services

## Setup

1. **Clone the repository** (if not already done):
   ```bash
   cd $HOME/code
   git clone <repository-url> rmm-infra
   cd rmm-infra
   ```

2. **Authenticate with Google Cloud**:
   ```bash
   gcloud auth application-default login
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Optional: Configure remote state backend**

   Uncomment and configure the backend block in `main.tf`:
   ```hcl
   backend "gcs" {
     bucket = "rustymaintenance-terraform-state"
     prefix = "rmm-infra"
   }
   ```

   Then create the GCS bucket and reinitialize:
   ```bash
   gsutil mb -p rustymaintenance gs://rustymaintenance-terraform-state
   terraform init -migrate-state
   ```

## Configuration

Default variables are set in `variables.tf`. You can override them by:
- Creating a `terraform.tfvars` file (not committed to git)
- Using `-var` flags with terraform commands
- Setting environment variables with `TF_VAR_` prefix

Key variables:
- `project_id`: GCP Project ID (default: `rustymaintenance`)
- `region`: GCP Region (default: `us-central1`)
- `domain`: Domain name (default: `rustymaintenanceman.com`)
- `cloud_run_service_name`: Cloud Run service name (default: `rmm-ui-service`)

## Deployment

### First-time Deployment

1. **Import existing Cloud Run service** (if it already exists):
   ```bash
   terraform import google_cloud_run_v2_service.default projects/rustymaintenance/locations/us-central1/services/rmm-ui-service
   ```

2. **Review the plan**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **Get the load balancer IP**:
   ```bash
   terraform output load_balancer_ip
   ```

### Updating Infrastructure

1. Make changes to Terraform files
2. Review the plan: `terraform plan`
3. Apply changes: `terraform apply`

## Post-Deployment Steps

After deploying the load balancer:

1. **Get the Load Balancer IP**:
   ```bash
   terraform output load_balancer_ip
   ```

2. **Configure DNS in Squarespace**:
   - Log in to Squarespace
   - Navigate to Settings > Domains > rustymaintenanceman.com
   - Add an A record pointing to the load balancer IP
   - If IPv6 is enabled, add an AAAA record as well

3. **Verify SSL Certificate**:
   - Monitor certificate status: `terraform output ssl_certificate_status`
   - Check in GCP Console: Network Services > Load Balancing > SSL Certificates
   - Certificate will provision automatically once DNS points to the load balancer (usually 10-60 minutes)

4. **Test the Setup**:
   - Wait for DNS propagation (can take up to 48 hours, typically much faster)
   - Access https://rustymaintenanceman.com
   - Verify SSL certificate is active and valid

## Outputs

- `load_balancer_ip`: External IP address of the load balancer
- `load_balancer_ipv6`: IPv6 address (if enabled)
- `ssl_certificate_name`: Name of the SSL certificate
- `ssl_certificate_status`: Status of the SSL certificate
- `url_map_name`: Name of the URL map

## Troubleshooting

### SSL Certificate Not Provisioning

- Ensure DNS A record points to the load balancer IP
- Wait 10-60 minutes for automatic provisioning
- Check certificate status: `terraform output ssl_certificate_status`
- Verify DNS propagation: `dig rustymaintenanceman.com`

### Cloud Run Service Not Accessible

- Verify ingress setting: `gcloud run services describe rmm-ui-service --region=us-central1`
- Ensure ingress is set to `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`
- Check load balancer backend service health

### Import Errors

If you get import errors for the Cloud Run service:
- Ensure the service exists: `gcloud run services list`
- Use the correct resource path format
- Check IAM permissions

## Resources

- [Google Cloud Load Balancing](https://cloud.google.com/load-balancing/docs)
- [Cloud Run Networking](https://cloud.google.com/run/docs/configuring/ingress)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

