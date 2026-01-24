---
description: Build and verify the infrastructure code
---

# Build Infrastructure

This workflow builds and verifies the Terraform infrastructure code.

## Steps

1. Initialize Terraform (if needed)
// turbo
```bash
terraform init
```

2. Format Terraform files
// turbo
```bash
terraform fmt -recursive
```

3. Validate Terraform configuration
// turbo
```bash
terraform validate
```

4. Plan infrastructure changes (dry run)
// turbo
```bash
terraform plan
```

## Notes

- All build commands are safe to auto-run
- `terraform plan` shows what would change without applying
- Never auto-run `terraform apply` - that requires manual approval
