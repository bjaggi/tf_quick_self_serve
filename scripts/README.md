# Scripts Directory

This directory contains deployment and management scripts for your Confluent Kafka infrastructure.

## Available Scripts

### 🚀 `deploy.sh` - Main Deployment Script
Handles planning, applying, and basic infrastructure management.

```bash
# Usage
./scripts/deploy.sh <environment> [action]

# Examples
./scripts/deploy.sh dev plan           # Plan changes for dev
./scripts/deploy.sh dev apply          # Apply changes to dev
./scripts/deploy.sh uat plan           # Plan changes for UAT
./scripts/deploy.sh prod apply         # Apply changes to production
```

**Actions:** `plan`, `apply`, `destroy`, `show`, `state`

**🔍 Automatic Logging:** All Terraform operations are automatically logged with:
- **Clean logs**: `logs/{environment}/{action}_{timestamp}.log` - Human-readable output
- **Full logs**: `logs/{environment}/{action}_{timestamp}_full.log` - Complete output with metadata
- **Session details**: Commands executed, exit codes, timestamps, user info

### 🗑️ `destroy.sh` - Advanced Destroy Script
Provides safe, controlled destruction of infrastructure with advanced options.

```bash
# Usage
./scripts/destroy.sh <environment> [options]

# Examples
./scripts/destroy.sh dev --plan                    # Show what would be destroyed
./scripts/destroy.sh dev --target=module.topics    # Destroy only topics
./scripts/destroy.sh uat --backup-state            # Backup state before destroy
./scripts/destroy.sh prod --force                  # Skip confirmations (dangerous!)
```

**Options:**
- `--plan` - Show destroy plan without executing
- `--target=<resource>` - Destroy specific resource(s)
- `--backup-state` - Backup state file before destroy
- `--force` - Skip confirmation prompts
- `--help` - Show help message

### 🔧 `init-backend.sh` - Backend Initialization
Initializes Terraform state backends for different environments.

```bash
./scripts/init-backend.sh <backend-type> <environment>
```

### 🛠️ `setup-dev.sh` - Development Setup
Sets up local development environment.

## Safety Features

### Production Protection
- **Extra confirmations** for production environments
- **Environment name verification** for prod destroys
- **Resource listing** before destruction
- **State backup options** before destructive operations

### State Management
- **Automatic state backups** with `--backup-state`
- **State file cleanup** after operations
- **Backend verification** before operations

### Error Handling
- **Credential validation** before operations
- **File existence checks** for tfvars and config files
- **Backend configuration verification**
- **Graceful error handling** with colored output

## Quick Start

1. **Initialize backend** (first time only):
   ```bash
   ./scripts/init-backend.sh local dev
   ```

2. **Plan your deployment**:
   ```bash
   ./scripts/deploy.sh dev plan
   ```

3. **Apply changes**:
   ```bash
   ./scripts/deploy.sh dev apply
   ```

4. **Destroy when needed**:
   ```bash
   ./scripts/destroy.sh dev --plan        # Review first
   ./scripts/destroy.sh dev --backup-state # Then destroy with backup
   ```

## Environment Variables

Both scripts support multiple secret management backends. For environment variable backend:

```bash
export CONFLUENT_CLOUD_API_KEY="your-cloud-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-cloud-api-secret"
```

## Best Practices

### Development
- Always run `--plan` first
- Use `--target` for selective operations
- Keep state backups for important environments

### Production
- **Always backup state** before destroys: `--backup-state`
- Use remote state backends (AWS S3, GCP GCS, Azure Storage)
- Never use `--force` in production
- Review plans carefully before applying

### Troubleshooting
- Check credential environment variables
- Verify tfvars and config files exist
- Ensure backend is properly initialized
- Use `terraform state list` to see current resources