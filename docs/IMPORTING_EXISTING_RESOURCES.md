# Importing Existing Confluent Cloud Resources

## Overview

This guide documents how to import existing Confluent Cloud resources into Terraform state using our automated import script. This is essential when you have resources that were created outside of Terraform and need to bring them under Terraform management.

## 🎯 When You Need This

### Common Scenarios:
1. **"Already exists" errors** during `terraform apply`
   ```
   Error: error creating Service Account "my-service": 409 Conflict: 
   Unable to create service account for organization: Service name is already in use.
   ```

2. **Empty destroy operations** - When `terraform destroy` shows no resources to destroy despite having infrastructure

3. **State drift** - Resources exist in Confluent Cloud but not in Terraform state

4. **Environment migration** - Moving from manual resource creation to Infrastructure as Code

## 🚀 The Import Script

Our automated import script (`./scripts/import-confluent-resources.sh`) handles:

- ✅ **Kafka Topics** - Discovers and imports all configured topics
- ✅ **Service Accounts** - Finds IDs and imports service accounts  
- ✅ **RBAC Bindings** - Provides guidance for complex role bindings
- ✅ **Multi-Environment** - Works with dev, uat, prod, or any custom environment
- ✅ **Dynamic Configuration** - Reads actual resource names from your JSON files

## 📋 Prerequisites

### Required Setup:
```bash
# 1. Confluent Cloud API credentials
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# 2. Terraform initialized
# (The script will handle this automatically)

# 3. Configuration files present
# Your environment JSON files in confluent_metadata/<env>/json/
```

### Required JSON Configuration Files:
- `confluent_metadata/<env>/json/topics.json`
- `confluent_metadata/<env>/json/service-accounts.json`  
- `confluent_metadata/<env>/json/rbac.json`

## 🛠️ Usage

### Basic Import Process:

```bash
# Step 1: Set your credentials
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# Step 2: Run the import script for your environment
./scripts/import-confluent-resources.sh <environment>

# Examples:
./scripts/import-confluent-resources.sh dev
./scripts/import-confluent-resources.sh uat  
./scripts/import-confluent-resources.sh prod
```

### Complete Workflow:

```bash
# 1. Import existing resources
./scripts/import-confluent-resources.sh dev

# 2. Verify what was imported
terraform state list

# 3. Run deployment (will only create missing resources)
./scripts/deploy.sh dev apply
```

## 📊 Expected Output

### Successful Import Example:
```
[INFO] 🚀 Starting Confluent Cloud Resource Import for environment: dev
[INFO] 📋 Environment Details:
   Cluster ID: lkc-y316j
   Environment ID: env-7qv2p
   Organization ID: fff39d13-91b7-444b-baa6-c0007e80e4d5

[INFO] 🏷️  Importing Kafka Topics...
[SUCCESS] ✅ Successfully imported topic 'user-events'
[SUCCESS] ✅ Successfully imported topic 'order-events'
[SUCCESS] ✅ Successfully imported topic 'payment-events'

[INFO] 👤 Importing Service Accounts...
[SUCCESS] ✅ Successfully imported service account 'user-service-dev'
[SUCCESS] ✅ Successfully imported service account 'order-service-dev'
[SUCCESS] ✅ Successfully imported service account 'payment-service-dev'

[INFO] 📊 Import Summary:
   Topics imported: 3 / 3
   Service Accounts imported: 3 / 3
   RBAC Bindings: Ready to create (5 bindings)
```

### After Import - terraform state list:
```bash
$ terraform state list
module.topics.confluent_kafka_topic.topics["user-events"]
module.topics.confluent_kafka_topic.topics["order-events"]  
module.topics.confluent_kafka_topic.topics["payment-events"]
module.service_accounts.confluent_service_account.service_accounts["user-service-dev"]
module.service_accounts.confluent_service_account.service_accounts["order-service-dev"]
module.service_accounts.confluent_service_account.service_accounts["payment-service-dev"]
```

## 🔧 Script Capabilities

### Dynamic Resource Discovery:
The script automatically:

1. **Reads your configuration** - Parses JSON files to know what resources to expect
2. **Discovers resource IDs** - Queries Confluent Cloud to find actual resource IDs
3. **Generates import commands** - Creates proper terraform import commands
4. **Executes imports** - Runs imports automatically with error handling
5. **Provides summary** - Shows what was imported and what needs attention

### Supported Resource Types:

| Resource Type | Import Method | Status |
|---------------|---------------|--------|
| **Kafka Topics** | Cluster ID + Topic Name | ✅ Fully Automated |
| **Service Accounts** | Dynamic ID Discovery | ✅ Fully Automated |
| **RBAC Bindings** | Complex CRN Patterns | ⚠️ Manual Guidance |
| **Schemas** | Registry + Subject | 📋 Planned |
| **Identity Pools** | OAuth Configuration | 📋 Planned |

## 🌍 Multi-Environment Support

### Environment-Specific Naming:
The script handles different naming conventions:

```json
// dev/json/service-accounts.json
{
  "service_accounts": [
    {"name": "user-service-dev"},
    {"name": "order-service-dev"}
  ]
}

// uat/json/service-accounts.json  
{
  "service_accounts": [
    {"name": "uat-user-service-dev"},
    {"name": "uat-order-service-dev"}
  ]
}

// prod/json/service-accounts.json
{
  "service_accounts": [
    {"name": "user-service-prod"},
    {"name": "order-service-prod"}
  ]
}
```

### Environment-Specific Execution:
```bash
# Development environment
./scripts/import-confluent-resources.sh dev

# UAT environment  
./scripts/import-confluent-resources.sh uat

# Production environment
./scripts/import-confluent-resources.sh prod
```

## 🔄 Integration with Deployment Workflow

### Before Import Script:
```bash
./scripts/deploy.sh dev apply
# ❌ Error: Service Account already exists
# ❌ Error: Topic already exists
```

### After Import Script:
```bash
# Step 1: Import existing resources
./scripts/import-confluent-resources.sh dev
# ✅ Successfully imported 6 resources

# Step 2: Deploy (creates only missing resources)  
./scripts/deploy.sh dev apply
# ✅ Created 5 RBAC bindings
# ✅ No conflicts, clean deployment
```

## 🛡️ Safety Features

### Built-in Protections:
1. **Dry-run capability** - Shows what will be imported before doing it
2. **Error handling** - Continues importing other resources if one fails
3. **Validation** - Verifies resources exist before attempting import
4. **Cleanup** - Removes temporary files automatically
5. **Logging** - All operations logged for audit trail

### Rollback Strategy:
```bash
# If import goes wrong, you can restore from backup
cp states/dev/terraform.tfstate.backup states/dev/terraform.tfstate

# Or re-run the import script (it's idempotent)
./scripts/import-confluent-resources.sh dev
```

## 🚨 Troubleshooting

### Common Issues:

#### 1. "Configuration for import target does not exist"
```bash
# Solution: Check your JSON configuration files
ls -la confluent_metadata/dev/json/
# Ensure service-accounts.json has the correct resource names
```

#### 2. "Service account not found"
```bash
# The resource name in JSON doesn't match Confluent Cloud
# Check actual resource names in Confluent Cloud Console
# Update your JSON configuration to match
```

#### 3. "Already imported" warnings
```bash
# This is normal - the script detects already imported resources
# No action needed, this protects against duplicate imports
```

#### 4. "Failed to query service accounts"
```bash
# Check your API credentials
echo $CONFLUENT_CLOUD_API_KEY
echo $CONFLUENT_CLOUD_API_SECRET

# Verify permissions in Confluent Cloud
```

### Debug Mode:
```bash
# Add debug flag to see detailed operations
./scripts/import-confluent-resources.sh dev --debug
```

## 📝 Best Practices

### Pre-Import Checklist:
- [ ] **Backup state files** - `cp states/dev/terraform.tfstate states/dev/terraform.tfstate.backup-$(date +%Y%m%d)`
- [ ] **Verify credentials** - Test API key access to Confluent Cloud
- [ ] **Check configurations** - Ensure JSON files match actual resource names
- [ ] **Test in dev first** - Always test import process in development environment

### Post-Import Validation:
```bash
# 1. Check what was imported
terraform state list

# 2. Verify no drift
terraform plan -var-file="environments/dev.tfvars"

# 3. Ensure clean apply
terraform apply -var-file="environments/dev.tfvars"
```

### Production Workflow:
```bash
# Production-ready import workflow
set -e  # Exit on any error

# Set credentials
export CONFLUENT_CLOUD_API_KEY="$PROD_API_KEY"
export CONFLUENT_CLOUD_API_SECRET="$PROD_API_SECRET"

# Backup current state
cp states/prod/terraform.tfstate states/prod/terraform.tfstate.backup-$(date +%Y%m%d_%H%M%S)

# Import resources
./scripts/import-confluent-resources.sh prod

# Validate
terraform plan -var-file="environments/prod.tfvars"

# Apply only if plan is clean
./scripts/deploy.sh prod apply
```

## 🔗 Related Documentation

- [Terraform State Management](./TERRAFORM_STATE_MANAGEMENT.md) - Managing state files
- [Deployment Guide](../HOW_TO_RUN.md) - Complete deployment workflow  
- [Backend Management](../BACKEND_MANAGEMENT.md) - State backend configuration
- [Troubleshooting Guide](../TROUBLESHOOTING.md) - Common issues and solutions

## 🎉 Success Stories

### Before Import Script:
- ❌ Manual resource imports taking hours
- ❌ Frequent "already exists" deployment errors
- ❌ State drift causing inconsistencies
- ❌ Fear of destroying existing resources

### After Import Script:  
- ✅ Automated imports in minutes
- ✅ Clean deployments without conflicts
- ✅ Complete resource tracking in Terraform
- ✅ Confidence in destroy operations

**The import script transforms manual, error-prone processes into reliable, automated workflows!** 🚀