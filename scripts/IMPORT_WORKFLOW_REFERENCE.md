# Import Workflow Quick Reference

## 🚨 Problem: "Already Exists" Errors

```bash
Error: error creating Service Account "my-service": 409 Conflict: 
Unable to create service account for organization: Service name is already in use.

Error: error creating Kafka Topic: 400 Bad Request: Topic 'my-topic' already exists.
```

## ✅ Solution: Automated Import

### Step 1: Set Credentials
```bash
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
```

### Step 2: Import Existing Resources
```bash
# For development environment
./scripts/import-confluent-resources.sh dev

# For UAT environment  
./scripts/import-confluent-resources.sh uat

# For production environment
./scripts/import-confluent-resources.sh prod
```

### Step 3: Deploy Normally
```bash
# Deploy after import (creates only missing resources)
./scripts/deploy.sh <env> apply
```

## 📋 Complete Workflow Examples

### New Environment Setup
```bash
# 1. Initialize backend
./scripts/init-backend.sh local dev

# 2. Import existing resources (if any)
./scripts/import-confluent-resources.sh dev

# 3. Deploy
./scripts/deploy.sh dev apply
```

### Production Deployment
```bash
# 1. Set production credentials
export CONFLUENT_CLOUD_API_KEY="$PROD_API_KEY"
export CONFLUENT_CLOUD_API_SECRET="$PROD_API_SECRET"

# 2. Initialize production backend
./scripts/init-backend.sh aws-s3 prod

# 3. Import existing production resources
./scripts/import-confluent-resources.sh prod

# 4. Plan and review
./scripts/deploy.sh prod plan

# 5. Deploy to production
./scripts/deploy.sh prod apply
```

### Multi-Environment Migration
```bash
# Migrate all environments to Terraform management

# Development
./scripts/import-confluent-resources.sh dev
./scripts/deploy.sh dev apply

# UAT
./scripts/import-confluent-resources.sh uat  
./scripts/deploy.sh uat apply

# Production
./scripts/import-confluent-resources.sh prod
./scripts/deploy.sh prod apply
```

## 🎯 Expected Results

### Before Import Script:
- ❌ "Already exists" errors during deployment
- ❌ Empty `terraform destroy` operations  
- ❌ State drift between Terraform and actual infrastructure
- ❌ Manual import commands needed

### After Import Script:
- ✅ Clean deployments without conflicts
- ✅ Complete resource tracking in `terraform state list`
- ✅ Proper destroy operations showing all resources
- ✅ Fully automated import process

## 🔍 Verification Commands

### Check What Was Imported
```bash
# List all resources in state
terraform state list

# Should show resources like:
# module.topics.confluent_kafka_topic.topics["user-events"]
# module.service_accounts.confluent_service_account.service_accounts["user-service-dev"]
```

### Verify Clean State
```bash
# Should show no changes needed
terraform plan -var-file="environments/dev.tfvars"

# Output: "No changes. Your infrastructure matches the configuration."
```

### Test Destroy (Optional)
```bash
# Should now show all resources that would be destroyed
terraform plan -destroy -var-file="environments/dev.tfvars"

# Should list topics, service accounts, RBAC bindings, etc.
```

## 🛡️ Safety Features

- ✅ **Idempotent** - Safe to run multiple times
- ✅ **Non-destructive** - Only imports, never destroys resources  
- ✅ **Validation** - Checks resources exist before importing
- ✅ **Error handling** - Continues if individual imports fail
- ✅ **Logging** - All operations logged for audit

## 📚 Full Documentation

- [Complete Import Guide](../docs/IMPORTING_EXISTING_RESOURCES.md)
- [State Management](../docs/TERRAFORM_STATE_MANAGEMENT.md)  
- [Deployment Guide](../HOW_TO_RUN.md)
- [Quick Start](../QUICK_START.md)