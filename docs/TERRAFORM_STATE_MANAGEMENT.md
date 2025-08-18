# Terraform State Management

## State Location

Your Terraform state is configured to use a **local backend** and is stored at:

```
📍 State File: ./states/dev/terraform.tfstate
📂 Working Directory: /home/ubuntu/tf_quick_self_serve (project root)
```

## Checking State Contents

To see what resources are currently tracked in Terraform state, run from the **project root directory**:

```bash
# Navigate to project root (if not already there)
cd /home/ubuntu/tf_quick_self_serve

# List all resources in state
terraform state list

# Get detailed information about a specific resource
terraform state show <resource_address>

# Example: Show details of a specific topic
terraform state show 'module.topics.confluent_kafka_topic.topics["user-events"]'
```

## Expected Resources in State

After running the import script, your state should contain:

### Topics (3)
```
module.topics.confluent_kafka_topic.topics["user-events"]
module.topics.confluent_kafka_topic.topics["order-events"] 
module.topics.confluent_kafka_topic.topics["payment-events"]
```

### Service Accounts (3)
```
module.service_accounts.confluent_service_account.service_accounts["user-service-dev"]
module.service_accounts.confluent_service_account.service_accounts["order-service-dev"]
module.service_accounts.confluent_service_account.service_accounts["payment-service-dev"]
```

### RBAC Bindings (5) - After terraform apply
```
module.rbac.confluent_role_binding.bindings["simplified-0"]
module.rbac.confluent_role_binding.bindings["simplified-1"]
module.rbac.confluent_role_binding.bindings["simplified-2"]
module.rbac.confluent_role_binding.bindings["simplified-3"]
module.rbac.confluent_role_binding.bindings["simplified-4"]
```

## Backend Configuration

Current backend configuration in `backend.tf`:

```hcl
terraform {
  backend "local" {
    path = "./states/dev/terraform.tfstate"
  }
}
```

## State File Management

### Backup State
```bash
# Create a backup of current state
cp states/dev/terraform.tfstate states/dev/terraform.tfstate.backup-$(date +%Y%m%d_%H%M%S)
```

### View State File Structure
```bash
# View state directory
ls -la states/dev/

# Check state file size and modification time  
ls -lh states/dev/terraform.tfstate
```

### Verify State Integrity
```bash
# Run plan to ensure state matches configuration
terraform plan -var-file="environments/dev.tfvars"

# Refresh state from actual infrastructure
terraform refresh -var-file="environments/dev.tfvars"
```

## Troubleshooting State Issues

### If State Becomes Corrupted
1. **Check backup files**: `ls -la states/dev/terraform.tfstate*`
2. **Restore from backup**: `cp states/dev/terraform.tfstate.backup-TIMESTAMP states/dev/terraform.tfstate`
3. **Re-run import script**: `./scripts/import-confluent-resources.sh dev`

### If Resources Exist But Not in State
1. **Use the import script**: `./scripts/import-confluent-resources.sh dev`
2. **Manual import if needed**: `terraform import -var-file="environments/dev.tfvars" <resource_address> <resource_id>`

### State Lock Issues (if using remote backend later)
```bash
# Force unlock if needed (use with caution)
terraform force-unlock <lock_id>
```

## Security Notes

⚠️ **Important**: The state file contains sensitive information including:
- Resource IDs
- Configuration details
- Potentially sensitive metadata

🔒 **Best Practices**:
- Never commit state files to version control (already in `.gitignore`)
- Backup state files securely
- Consider remote backend for production environments
- Use encryption for state storage in production

## Related Documentation

- [Backend Management](../BACKEND_MANAGEMENT.md) - Managing different backend types
- [Import Script](../scripts/import-confluent-resources.sh) - Automated resource import
- [Deployment Guide](../HOW_TO_RUN.md) - Complete deployment workflow