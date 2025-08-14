# 🚀 How to Run: Complete Step-by-Step Guide

This guide will walk you through running the Confluent Kafka Infrastructure as Code solution from scratch to production deployment.

> **🗂️ State Organization**: This solution automatically organizes Terraform state files in `states/dev/`, `states/uat/`, and `states/prod/` directories for clean project structure and better team collaboration.

## 📋 Prerequisites Checklist

Before you start, ensure you have:

- ✅ [Terraform](https://www.terraform.io/downloads) >= 1.0 installed
- ✅ [Confluent Cloud Account](https://confluent.cloud/) with API keys
- ✅ Your cloud provider CLI installed (if using remote backend):
  - AWS CLI for AWS S3 backend
  - Google Cloud CLI for GCP backend  
  - Azure CLI for Azure backend

## 🎯 Quick Start (5 Minutes)

### Step 1: Get Your Confluent Cloud Details

1. **Login to Confluent Cloud Console**
2. **Get your API Keys:**
   - Go to "Cloud API Keys" → "Add Key"
   - Copy the API Key and Secret
3. **Get your Resource IDs:**
   - Environment ID: Go to your environment, copy the ID from URL
   - Cluster ID: Go to your Kafka cluster, copy the ID from overview
   - Schema Registry ID: (Optional) Go to Schema Registry, copy the ID

### Step 2: Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd tf_quick_self_serve

# Make scripts executable (if needed)
chmod +x scripts/*.sh
chmod +x examples/backends/*.sh
```

### Step 3: Choose Your Path

#### 🏠 **Development Setup (Fastest)**

```bash
# 1. Set environment variables
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# 2. Update dev configuration
vim environments/dev.tfvars
# Change: cluster_id, environment_id, schema_registry_id

# 3. Initialize local backend
./scripts/init-backend.sh local dev

# 4. Deploy
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply
```

#### 🏢 **Production Setup (Recommended)**

```bash
# 1. Choose your cloud provider and setup backend
./examples/backends/prod-aws.sh      # For AWS
# OR
./examples/backends/prod-gcp.sh      # For GCP  
# OR
./examples/backends/prod-azure.sh    # For Azure

# 2. Setup secrets (choose one method)
# AWS Secrets Manager example:
aws secretsmanager create-secret \
  --name "confluent-cloud-credentials-prod" \
  --secret-string '{"api_key":"your-key","api_secret":"your-secret"}'

# 3. Update prod configuration
vim environments/prod.tfvars
# Change: cluster_id, environment_id, schema_registry_id, secret settings

# 4. Deploy
./scripts/deploy.sh prod plan
./scripts/deploy.sh prod apply
```

## 📝 Detailed Step-by-Step Instructions

### Phase 1: Environment Preparation

#### 1.1 Configure Confluent Cloud Credentials

**Option A: Environment Variables (Development)**
```bash
export CONFLUENT_CLOUD_API_KEY="your-confluent-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-confluent-api-secret"
```

**Option B: External Secret Management (Production)**
```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name "confluent-cloud-credentials-prod" \
  --secret-string '{"api_key":"your-key","api_secret":"your-secret"}'

# Azure Key Vault
az keyvault secret set \
  --vault-name "your-vault" \
  --name "confluent-api-key" \
  --value "your-key"

# See SECRETS_MANAGEMENT.md for all options
```

#### 1.2 Update Environment Configuration

Edit the appropriate `.tfvars` file:

```bash
# For development
vim environments/dev.tfvars

# For production
vim environments/prod.tfvars
```

**Required Changes:**
```hcl
# Replace these with your actual values
environment        = "dev"  # or "uat", "prod"
cluster_id        = "lkc-your-actual-cluster-id"
environment_id    = "env-your-actual-environment-id"
schema_registry_id = "lsrc-your-schema-registry-id"  # Optional

# Configure secret management
secret_backend = "environment_variables"  # or aws_secrets_manager, etc.
```

### Phase 2: Backend Configuration

#### 2.1 Choose Your Backend Strategy

| Environment | Recommended Backend | Command |
|-------------|-------------------|---------|
| **Development** | Local | `./scripts/init-backend.sh local dev` |
| **UAT/Staging** | Cloud Remote | `./scripts/init-backend.sh aws-s3 uat` |
| **Production** | Cloud Remote | `./scripts/init-backend.sh aws-s3 prod` |

#### 2.2 Initialize Backend

**For Development (Local):**
```bash
./scripts/init-backend.sh local dev
```

**For Production (AWS S3):**
```bash
# Option 1: Quick setup with example script
./examples/backends/prod-aws.sh

# Option 2: Manual setup
./scripts/init-backend.sh aws-s3 prod
```

**For Production (GCP Cloud Storage):**
```bash
# Option 1: Quick setup with example script
./examples/backends/prod-gcp.sh

# Option 2: Manual setup
./scripts/init-backend.sh gcp-gcs prod
```

**For Production (Azure Storage):**
```bash
# Option 1: Quick setup with example script
./examples/backends/prod-azure.sh

# Option 2: Manual setup
./scripts/init-backend.sh azure-storage prod
```

### Phase 3: Customize Your Infrastructure

#### 3.1 Edit Configuration Files

The main configuration is in YAML files that developers can edit without Terraform knowledge:

```bash
# Edit development configuration
vim config/dev/config.yaml

# Edit production configuration  
vim config/prod/config.yaml
```

**Example customizations:**

```yaml
# Add a new topic
topics:
  my-new-service-events:
    partitions: 12
    config:
      "cleanup.policy": "delete"
      "retention.ms": "604800000"  # 7 days

# Add a new service account
service_accounts:
  my-new-service-prod:
    description: "Service account for my new service"

# Add RBAC permissions
rbac_bindings:
  my-service-producer:
    principal_type: "service_account"
    principal_name: "my-new-service-prod"
    role_name: "DeveloperWrite"
    crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=my-new-service-events"
```

#### 3.2 Add Custom Schemas (Optional)

```bash
# Create your AVRO schema
cat > confluent_metadata/schemas/my-service-events-value.avsc << 'EOF'
{
  "type": "record",
  "name": "MyServiceEvent",
  "namespace": "com.mycompany.events",
  "fields": [
    {"name": "id", "type": "string"},
    {"name": "timestamp", "type": "long"},
    {"name": "data", "type": "string"}
  ]
}
EOF

# Reference it in your config
vim config/dev/config.yaml
# Add:
# schemas:
#   my-service-events-value:
#     format: "AVRO"
#     schema_file: "confluent_metadata/schemas/my-service-events-value.avsc"
```

### Phase 4: Deploy Infrastructure

#### 4.1 Plan Your Deployment

```bash
# Plan changes for development
./scripts/deploy.sh dev plan

# Plan changes for production
./scripts/deploy.sh prod plan
```

#### 4.2 Apply Changes

```bash
# Apply to development
./scripts/deploy.sh dev apply

# Apply to production (after careful review)
./scripts/deploy.sh prod apply
```

#### 4.3 Verify Deployment

```bash
# Show what was created
terraform output

# List all resources
terraform state list

# Get details of specific resources
terraform state show 'module.topics.confluent_kafka_topic.topics["user-events"]'
```

## 🔄 Environment Promotion Workflow

### Promote from Dev to UAT to Prod

1. **Develop and test in dev:**
```bash
# Edit config/dev/config.yaml
vim config/dev/config.yaml

# Deploy to dev
./scripts/deploy.sh dev apply
```

2. **Promote to UAT:**
```bash
# Copy working config from dev to uat (with modifications)
cp config/dev/config.yaml config/uat/config.yaml

# Edit for UAT-specific settings (more partitions, longer retention, etc.)
vim config/uat/config.yaml

# Update service account names from *-dev to *-uat
sed -i 's/-dev/-uat/g' config/uat/config.yaml

# Deploy to UAT
./scripts/deploy.sh uat apply
```

3. **Promote to Production:**
```bash
# Copy validated config from uat to prod (with modifications)
cp config/uat/config.yaml config/prod/config.yaml

# Edit for production settings (higher partitions, longer retention, higher replication)
vim config/prod/config.yaml

# Update service account names from *-uat to *-prod
sed -i 's/-uat/-prod/g' config/prod/config.yaml

# Deploy to production
./scripts/deploy.sh prod apply
```

## 🛠️ Common Operations

### Adding New Resources

#### Add a New Topic
```bash
# Edit the config file
vim config/dev/config.yaml

# Add to topics section:
# new-topic-name:
#   partitions: 6
#   config:
#     "cleanup.policy": "delete"
#     "retention.ms": "604800000"

# Deploy
./scripts/deploy.sh dev apply
```

#### Add a New Service Account
```bash
# Edit the config file
vim config/dev/config.yaml

# Add to service_accounts section:
# new-service-dev:
#   description: "Service account for new service"

# Add RBAC permissions in rbac_bindings section:
# new-service-permissions:
#   principal_type: "service_account"
#   principal_name: "new-service-dev"
#   role_name: "DeveloperWrite"
#   crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=new-topic-name"

# Deploy
./scripts/deploy.sh dev apply
```

### Managing State

```bash
# View current state
terraform show

# List resources
terraform state list

# Import existing resource
terraform import 'module.topics.confluent_kafka_topic.topics["existing-topic"]' lkc-cluster-id/existing-topic

# Remove resource from state (without destroying)
terraform state rm 'module.topics.confluent_kafka_topic.topics["old-topic"]'
```

### Switching State Backends

```bash
# Export current state
terraform state pull > backup-state.json

# Initialize new backend
./scripts/init-backend.sh gcp-gcs prod

# Import state to new backend (if needed)
terraform state push backup-state.json
```

## 🐛 Troubleshooting Common Issues

### 1. Backend Not Initialized
```
Error: Backend configuration not found!
```
**Solution:**
```bash
./scripts/init-backend.sh local dev  # or appropriate backend
```

### 2. Credentials Not Set
```
Error: Invalid provider configuration
```
**Solution:**
```bash
# For environment variables
export CONFLUENT_CLOUD_API_KEY="your-key"
export CONFLUENT_CLOUD_API_SECRET="your-secret"

# For AWS
aws configure

# For GCP
gcloud auth login

# For Azure
az login
```

### 2.1. Cloud Provider Errors When Using Local Backend
```
Error: Please run 'az login' to setup account
Error: NoCredentialProviders: no valid providers in chain  
Error: Unable to configure API client: vault: no server provided
```

**Problem:** You chose local backend but Terraform still tries to initialize cloud providers.

**Quick Fix:**
```bash
# Use the development setup script (recommended)
./scripts/setup-dev.sh
```

**Manual Fix:**
```bash
# 1. Comment out unused providers in terraform.tf
# provider "aws" { ... }      # Comment this out
# provider "azurerm" { ... }  # Comment this out  
# provider "vault" { ... }    # Comment this out

# 2. Comment out unused providers in modules/secrets/providers.tf
# aws = { source = "hashicorp/aws", version = ">= 5.0" }      # Comment out
# azurerm = { source = "hashicorp/azurerm", version = ">= 3.0" }  # Comment out
# vault = { source = "hashicorp/vault", version = ">= 3.0" }     # Comment out

# 3. Re-run terraform init
terraform init
```

**When to Uncomment:** Only uncomment providers when you actually use that secret backend:
- Uncomment `aws` when `secret_backend = "aws_secrets_manager"`
- Uncomment `azurerm` when `secret_backend = "azure_keyvault"`  
- Uncomment `vault` when `secret_backend = "hashicorp_vault"`

### 3. Resource Already Exists
```
Error: resource already exists
```
**Solution:**
```bash
# Import existing resource
terraform import 'module.topics.confluent_kafka_topic.topics["topic-name"]' cluster-id/topic-name
```

### 4. Permission Denied
```
Error: 403 Forbidden
```
**Solution:**
- Check your API keys have sufficient permissions
- Verify cloud provider credentials
- Review IAM/RBAC policies

## 🔍 Verification Commands

### Check Deployment Status
```bash
# Show outputs
terraform output

# Verify secret backend
terraform output secret_backend_used

# Show topic details
terraform state show 'module.topics.confluent_kafka_topic.topics["user-events"]'

# List all service accounts
terraform state list | grep service_account
```

### Test Connectivity
```bash
# Test Confluent Cloud connection
confluent login

# List topics
confluent kafka topic list --cluster $CLUSTER_ID

# List service accounts
confluent iam service-account list
```

## 📈 Scaling and Monitoring

### Monitor Resource Usage
```bash
# Check state file size
ls -lh terraform*.tfstate

# Monitor costs (if using cloud backends)
aws s3 ls s3://your-terraform-state-bucket --recursive --human-readable
```

### Scale Resources
```bash
# Edit config to increase partitions
vim config/prod/config.yaml
# Change partitions: 6 to partitions: 12

# Apply changes
./scripts/deploy.sh prod apply
```

## 📋 Logging and Audit Trail

All deployment operations are automatically logged for audit trails, troubleshooting, and compliance:

### 🔍 **Automatic Logging**
Every time you run deployment scripts, comprehensive logs are created:

```bash
# All operations are logged automatically
./scripts/deploy.sh dev plan     # Creates logs/dev/plan_YYYYMMDD_HHMMSS.log
./scripts/deploy.sh dev apply    # Creates logs/dev/apply_YYYYMMDD_HHMMSS.log
./scripts/destroy.sh dev         # Creates logs/dev/destroy_YYYYMMDD_HHMMSS.log
```

### 📁 **Log File Structure**
```
logs/
├── dev/
│   ├── plan_20250805_143022.log          # Clean, human-readable output
│   ├── plan_20250805_143022_full.log     # Complete output with metadata
│   ├── apply_20250805_143045.log         # Clean deployment output
│   └── apply_20250805_143045_full.log    # Full deployment output
├── uat/
│   └── ...
└── prod/
    └── ...
```

### 📊 **What Gets Logged**
- **Session Metadata**: Timestamp, environment, action, user, working directory
- **Command Details**: Exact Terraform commands executed
- **Full Output**: All stdout and stderr from Terraform operations
- **Exit Codes**: Success/failure status of each operation
- **Timing**: Start and end times for each operation

### 🔍 **Using Logs for Troubleshooting**
```bash
# View the last deployment logs
ls -la logs/dev/ | tail -5

# Check for errors in the latest deployment
grep -i error logs/dev/apply_*_full.log | tail -10

# View complete session details
cat logs/dev/apply_20250805_143045_full.log

# Find all failed operations
grep "Exit code: [^0]" logs/**/*_full.log
```

### ✅ **Benefits**
- **🛡️ Audit Compliance**: Complete record of who did what, when
- **🐛 Troubleshooting**: Full context for debugging failures  
- **📈 Performance Tracking**: Monitor deployment times and patterns
- **🔄 Reproducibility**: Exact commands and outputs preserved
- **👥 Team Collaboration**: Shared understanding of changes

## 🎉 Success!

You now have a fully functional Confluent Kafka infrastructure managed through code! Your team can:

- ✅ Manage infrastructure through simple YAML files
- ✅ Promote changes safely across environments  
- ✅ Collaborate with shared remote state
- ✅ Scale resources as needed
- ✅ Maintain security with proper secret management
- ✅ Track all changes with comprehensive audit logs

## 📚 Next Steps

1. **Set up CI/CD**: Integrate with your CI/CD pipeline
2. **Monitor Costs**: Set up billing alerts for cloud resources
3. **Backup State**: Regular state file backups
4. **Documentation**: Document your specific configurations
5. **Training**: Train your team on the YAML configuration format

Need help? Check the detailed guides:
- [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md) - Secret management
- [BACKEND_MANAGEMENT.md](BACKEND_MANAGEMENT.md) - Backend configuration
- [LOGGING.md](LOGGING.md) - Comprehensive logging and audit trails
- [README.md](README.md) - Complete documentation 