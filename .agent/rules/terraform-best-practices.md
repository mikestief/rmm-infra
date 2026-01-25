# Terraform Best Practices

## State Management
- Use remote state for all production resources.
- Never commit execution plans or state files to version control.

## HCL Styling
- Always run `terraform fmt` before committing.
- Use meaningful resource names.
