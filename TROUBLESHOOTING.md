# 🔧 Troubleshooting Guide

This guide covers common issues you might encounter when running the Confluent Kafka Infrastructure as Code solution.

## 🚨 Most Common Issues

### 1. Cloud Provider Authentication Errors (Local Backend)

**Symptoms:**
```bash
Error: Please run 'az login' to setup account
Error: NoCredentialProviders: no valid providers in chain
Error: Unable to configure API client: vault: no server provided
```

**Why This Happens:**
You chose local backend for development, but Terraform still tries to initialize ALL cloud providers defined in `terraform.tf`, even the ones you're not using.

**🎯 Quick Fix (Recommended):**
```bash
# Use the development setup script - it handles everything
./scripts/setup-dev.sh
```

**🔧 Manual Fix:**

1. **Comment out unused providers in `terraform.tf`:**
```hcl
# Comment out providers you're not using
# provider "aws" {
#   # AWS credentials should be provided via AWS CLI, IAM roles, or environment variables
# }

# provider "azurerm" {
#   # features {}
# }

# provider "vault" {
#   # Vault address and token should be provided via environment variables
# }
```

2. **Comment out unused providers in `modules/secrets/providers.tf`:**
```hcl
terraform {
  required_providers {
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = ">= 5.0"
    # }
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = ">= 3.0"
    # }
    # vault = {
    #   source  = "hashicorp/vault"
    #   version = ">= 3.0"
    # }
  }
}
```

3. **Reinitialize Terraform:**
```bash
rm -rf .terraform
terraform init
```

**When to Uncomment Providers:**
- Uncomment `aws` only when using `secret_backend = "aws_secrets_manager"`
- Uncomment `azurerm` only when using `secret_backend = "azure_keyvault"`
- Uncomment `vault` only when using `secret_backend = "hashicorp_vault"`

---

### 2. Backend Configuration Not Found

**Symptoms:**
```bash
Error: Backend configuration not found!
```

**Solution:**
```bash
# Initialize your backend first
./scripts/init-backend.sh local dev          # For development
./scripts/init-backend.sh aws-s3 prod        # For production
```

---

### 3. Confluent Provider Issues

**Symptoms:**
```bash
Error: provider registry registry.terraform.io does not have a provider named 
registry.terraform.io/hashicorp/confluent
```

**Why This Happens:**
The provider source is incorrect. Confluent provider is `confluentinc/confluent`, not `hashicorp/confluent`.

**Solution:**
This should already be fixed in all modules, but if you see this error:
```bash
# Check all provider configurations
grep -r "hashicorp/confluent" .
# Should return no results

# All modules should use:
# source = "confluentinc/confluent"
```

---

### 4. Confluent Cloud Authentication

**Symptoms:**
```bash
Error: 401 Unauthorized
Error: Invalid provider configuration
```

**Solution:**
```bash
# Check your environment variables
echo $CONFLUENT_CLOUD_API_KEY
echo $CONFLUENT_CLOUD_API_SECRET

# If empty, set them:
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# For Terraform to pick them up:
export TF_VAR_confluent_api_key_env_var="$CONFLUENT_CLOUD_API_KEY"
export TF_VAR_confluent_api_secret_env_var="$CONFLUENT_CLOUD_API_SECRET"
```

---

### 5. Resource Configuration Issues

**Symptoms:**
```bash
Error: cluster lkc-xxxxx was not found
Error: environment env-xxxxx was not found
```

**Solution:**
Update your environment configuration files:
```bash
# Edit the appropriate file
vim environments/dev.tfvars    # For development
vim environments/prod.tfvars   # For production

# Replace placeholders with actual IDs:
cluster_id        = "lkc-your-actual-cluster-id"
environment_id    = "env-your-actual-environment-id"
schema_registry_id = "lsrc-your-actual-schema-registry-id"
```

---

## 🎛️ Environment-Specific Troubleshooting

### Development Environment

**Common Setup:**
```bash
# 1. Set credentials
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# 2. Update cluster details
vim environments/dev.tfvars

# 3. Use the development setup script
./scripts/setup-dev.sh

# 4. If script fails, try manual setup:
./scripts/init-backend.sh local dev
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply
```

### Production Environment

**Common Setup:**
```bash
# 1. Setup remote backend
./examples/backends/prod-aws.sh      # For AWS
./examples/backends/prod-gcp.sh      # For GCP
./examples/backends/prod-azure.sh    # For Azure

# 2. Setup external secret management
# See SECRETS_MANAGEMENT.md

# 3. Update configuration
vim environments/prod.tfvars

# 4. Deploy
./scripts/deploy.sh prod plan
./scripts/deploy.sh prod apply
```

---

## 🔍 Diagnostic Commands

### Check Current Configuration
```bash
# Show current backend
cat backend.tf

# Show current providers
terraform providers

# Validate configuration
terraform validate

# Check environment variables
env | grep CONFLUENT
env | grep TF_VAR
```

### Debug Terraform Issues
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan -var-file="environments/dev.tfvars"

# Check state
terraform show
terraform state list

# Test provider authentication
terraform console
# Then try: data.confluent_environment.test
```

### Check Confluent Cloud Connectivity
```bash
# Test API access (if you have confluent CLI)
confluent login --prompt
confluent environment list
confluent kafka cluster list
```

---

## 📋 Step-by-Step Recovery

If you're completely stuck, follow this recovery process:

### 1. Clean Reset
```bash
# Remove all Terraform state and cache
rm -rf .terraform
rm -f terraform*.tfstate*
rm -f backend.tf
rm -f *.tfplan
```

### 2. Check Prerequisites
```bash
# Terraform installed?
terraform version

# Credentials set?
echo $CONFLUENT_CLOUD_API_KEY
echo $CONFLUENT_CLOUD_API_SECRET

# Configuration updated?
grep "lkc-xxxxxx" environments/dev.tfvars  # Should return nothing
```

### 3. Use Development Setup Script
```bash
# This handles most common issues automatically
./scripts/setup-dev.sh
```

### 4. Manual Setup (If Script Fails)
```bash
# Initialize backend
./scripts/init-backend.sh local dev

# Set Terraform variables
export TF_VAR_confluent_api_key_env_var="$CONFLUENT_CLOUD_API_KEY"
export TF_VAR_confluent_api_secret_env_var="$CONFLUENT_CLOUD_API_SECRET"

# Plan and apply
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

---

## 🆘 Getting Help

If you're still stuck after trying these solutions:

1. **Check the deployment logs:** All operations are automatically logged to `logs/{environment}/` - review the latest `*_full.log` file for complete error details
2. **Check the logs:** Run with `TF_LOG=DEBUG` to see detailed error messages
3. **Verify prerequisites:** Make sure all required tools and credentials are properly configured
4. **Use the development setup script:** `./scripts/setup-dev.sh` handles most common issues
5. **Check the documentation:**
   - [README.md](README.md) - Complete solution overview
   - [HOW_TO_RUN.md](HOW_TO_RUN.md) - Step-by-step execution guide
   - [LOGGING.md](LOGGING.md) - Comprehensive logging and audit trails
   - [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md) - Secret management setup
   - [BACKEND_MANAGEMENT.md](BACKEND_MANAGEMENT.md) - Backend configuration

### Common Success Pattern

Most users succeed with this simple flow:
```bash
# 1. Set credentials
export CONFLUENT_CLOUD_API_KEY="your-key"
export CONFLUENT_CLOUD_API_SECRET="your-secret"

# 2. Update cluster details in environments/dev.tfvars
# 3. Run the development setup
./scripts/setup-dev.sh

# 4. Deploy
./scripts/deploy.sh dev apply
```

The development setup script handles provider issues, backend initialization, and environment variable setup automatically.

## 📋 Using Deployment Logs for Troubleshooting

All deployment operations are automatically logged with full details for easy troubleshooting:

### 🔍 **Quick Log Analysis**
```bash
# Check the latest deployment logs
ls -la logs/{environment}/ | tail -5

# Find error messages in the latest logs
grep -i "error\|failed\|exception" logs/dev/*_full.log | tail -10

# View complete session details
cat logs/dev/apply_$(ls -t logs/dev/apply_*_full.log | head -1 | cut -d'/' -f3)

# Search for specific error patterns
grep -r "timeout\|connection refused\|unauthorized" logs/
```

### 📊 **Log File Types**
- **`{action}_{timestamp}.log`**: Clean, human-readable output
- **`{action}_{timestamp}_full.log`**: Complete output with metadata, commands, exit codes

### 💡 **Common Log-Based Solutions**
```bash
# Authentication errors
grep -i "unauthorized\|forbidden\|authentication" logs/**/*_full.log

# Network connectivity issues  
grep -i "timeout\|connection\|network" logs/**/*_full.log

# Resource conflicts
grep -i "already exists\|conflict\|duplicate" logs/**/*_full.log

# Permission issues
grep -i "permission\|access denied\|rbac" logs/**/*_full.log
```

All logs include session metadata (user, timestamp, environment, commands) for complete audit trails. 