# Confluent Kafka Infrastructure as Code

A comprehensive Terraform solution for managing Confluent Kafka infrastructure with externalized configuration files, supporting multiple environments (dev/uat/prod) and easy promotion workflows.

## 🚀 Capabilities

This Terraform solution provides automated management of:

- **Kafka Topics**: Create and configure topics with partition counts and topic-level configurations
- **Service Accounts**: Manage service accounts for application authentication
- **Identity Pools**: Configure identity pools for user-based authentication via OAuth/OIDC
- **RBAC Permissions**: Assign role-based access control to service accounts and identity pools
- **Schema Registry**: Manage AVRO/JSON/Protobuf schemas with versioning
- **Multi-Environment Support**: Separate configurations for dev, uat, and prod environments
- **Environment Promotion**: Easy promotion of configurations across environments
- **Automated Resource Import**: Smart import of existing Confluent Cloud resources into Terraform state
- **Comprehensive Logging**: Automatic capture of all Terraform operations with timestamped logs for audit trails and troubleshooting

## 📋 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Confluent Cloud Account](https://confluent.cloud/)
- [Confluent CLI](https://docs.confluent.io/confluent-cli/current/install.html) (optional, for manual operations)

### Confluent Cloud Setup
1. **API Keys**: Create Cloud API Key and Secret in Confluent Cloud
   - Go to Cloud API Keys in Confluent Cloud Console
   - Create a new API key with appropriate permissions

2. **Resources**: Have the following resources ready:
   - Confluent Environment ID
   - Kafka Cluster ID(s) for each environment
   - Schema Registry Cluster ID (if using schemas)
   - Identity Provider ID (if using identity pools)

### Secret Management Setup
This solution supports multiple secret backends for enhanced security:

- **Environment Variables** (default): Simple setup for development
- **AWS Secrets Manager**: Enterprise-grade security for AWS environments
- **Azure Key Vault**: Enterprise-grade security for Azure environments  
- **HashiCorp Vault**: Multi-cloud enterprise secret management
- **Terraform Cloud**: Integrated secret management for Terraform Cloud users

See [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md) for detailed setup instructions.

### Backend Configuration Setup
This solution supports multiple backend types for flexible state management:

- **Local Backend**: Simple local state storage for development
- **AWS S3 Backend**: Simple remote state with S3 storage (no locking)
- **GCP Cloud Storage**: Google Cloud native state management with built-in locking
- **Azure Storage**: Azure native state management with built-in locking

> Recommendation: Keep `states/` for local-only dev and backups; use remote backends for shared envs.

See [BACKEND_MANAGEMENT.md](BACKEND_MANAGEMENT.md) for detailed backend configuration instructions.

## 📁 Project Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── terraform.tf              # Provider configuration
├── states/                    # 🗂️ Organized state management
│   ├── dev/                  # Development environment states
│   │   ├── terraform.tfstate # Dev state file
│   │   └── *.tfplan         # Dev plan files
│   ├── uat/                  # UAT environment states
│   ├── prod/                 # Production environment states
│   └── README.md            # State organization guide
├── modules/                   # Terraform modules
│   ├── topics/               # Kafka topics module
│   ├── service_accounts/     # Service accounts module
│   ├── identity_pools/       # Identity pools module
│   ├── rbac/                 # RBAC permissions module
│   ├── schemas/              # Schema registry module
│   └── secrets/              # Secret management module
├── config/                   # Environment configurations
│   ├── dev/config.yaml       # Development configuration
│   ├── uat/config.yaml       # UAT configuration
│   └── prod/config.yaml      # Production configuration
├── environments/             # Environment-specific variables
│   ├── dev.tfvars           # Development variables
│   ├── uat.tfvars           # UAT variables
│   └── prod.tfvars          # Production variables
├── tf_state_externalized/    # Backend configuration templates
│   ├── local.tf             # Local backend (development)
│   ├── aws-s3.tf            # AWS S3 backend (production)
│   ├── gcp-gcs.tf           # GCP Cloud Storage backend
│   └── azure-storage.tf     # Azure Storage backend
├── examples/                 # Example configurations
│   ├── secrets/             # Secret management examples
│   │   ├── aws-secrets-manager.tfvars
│   │   ├── azure-keyvault.tfvars
│   │   ├── hashicorp-vault.tfvars
│   │   └── terraform-cloud.tfvars
│   └── backends/            # Backend setup examples
│       ├── dev-local.sh
│       ├── prod-aws.sh
│       ├── prod-azure.sh
│       └── prod-gcp.sh
├── tf_state_externalized/   # Terraform backend templates
│   ├── local.tf            # Local backend configuration
│   ├── aws-s3.tf           # AWS S3 backend configuration
│   ├── gcp-gcs.tf          # GCP Cloud Storage backend
│   └── azure-storage.tf    # Azure Storage backend
├── confluent_metadata/       # Configuration and schema files
│   ├── user-events-value.avsc
│   ├── order-events-value.avsc
│   └── payment-events-value.avsc
├── docs/                    # Additional documentation
│   ├── TERRAFORM_STATE_MANAGEMENT.md  # State management guide
│   └── IMPORTING_EXISTING_RESOURCES.md # Import existing resources guide
├── README.md                # This documentation
├── SECRETS_MANAGEMENT.md    # Detailed secret management guide
├── BACKEND_MANAGEMENT.md    # Backend configuration guide
└── QUICK_START.md           # 5-minute setup guide
```

## 🛠️ Setup Instructions

### 1. Clone and Configure

```bash
# Clone the repository (if using git)
git clone <repository-url>
cd tf_quick_self_serve

# Set up Confluent Cloud credentials (if using environment variables)
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# OR configure external secret management - see SECRETS_MANAGEMENT.md
```

### 2. Update Environment Variables

Edit the appropriate environment file:

**For Development:**
```bash
# Edit environments/dev.tfvars
environment        = "dev"
cluster_id        = "lkc-your-dev-cluster-id"
environment_id    = "env-your-dev-environment-id"
schema_registry_id = "lsrc-your-schema-registry-id"  # Optional
schema_registry_rest_endpoint = "https://psrc-xxxxx.region.provider.confluent.cloud"  # If using schemas
kafka_rest_endpoint = "https://pkc-your-cluster.region.provider.confluent.cloud:443"
kafka_api_key    = "your-kafka-api-key"
kafka_api_secret = "your-kafka-api-secret"
schema_registry_api_key    = "your-schema-registry-api-key"     # If using schemas
schema_registry_api_secret = "your-schema-registry-api-secret" # If using schemas
```

**For UAT:**
```bash
# Edit environments/uat.tfvars
environment        = "uat"
cluster_id        = "lkc-your-uat-cluster-id"
environment_id    = "env-your-uat-environment-id"
schema_registry_id = "lsrc-your-schema-registry-id"  # Optional
schema_registry_rest_endpoint = "https://psrc-xxxxx.region.provider.confluent.cloud"  # If using schemas
kafka_rest_endpoint = "https://pkc-your-cluster.region.provider.confluent.cloud:443"
kafka_api_key    = "your-kafka-api-key"
kafka_api_secret = "your-kafka-api-secret"
schema_registry_api_key    = "your-schema-registry-api-key"     # If using schemas
schema_registry_api_secret = "your-schema-registry-api-secret" # If using schemas
```

**For Production:**
```bash
# Edit environments/prod.tfvars
environment        = "prod"
cluster_id        = "lkc-your-prod-cluster-id"
environment_id    = "env-your-prod-environment-id"
schema_registry_id = "lsrc-your-schema-registry-id"  # Optional
schema_registry_rest_endpoint = "https://psrc-xxxxx.region.provider.confluent.cloud"  # If using schemas
kafka_rest_endpoint = "https://pkc-your-cluster.region.provider.confluent.cloud:443"
kafka_api_key    = "your-kafka-api-key"
kafka_api_secret = "your-kafka-api-secret"
schema_registry_api_key    = "your-schema-registry-api-key"     # If using schemas
schema_registry_api_secret = "your-schema-registry-api-secret" # If using schemas
```

### 3. Update Configuration Files

Edit the YAML configuration files to match your requirements:

- `config/dev/config.yaml` - Development environment resources
- `config/uat/config.yaml` - UAT environment resources  
- `config/prod/config.yaml` - Production environment resources

### 4. Update Identity Provider ID

If using identity pools, update the `identity_provider_id` in each config file:

```yaml
identity_pools:
  dev-engineers:
    identity_provider_id: "op-your-actual-provider-id"  # Replace with actual ID
```

## 🚀 Usage Commands

### Initialize Backend and Terraform

```bash
# Initialize backend first (choose appropriate backend for your environment)
./scripts/init-backend.sh local dev          # For development
./scripts/init-backend.sh aws-s3 prod        # For production on AWS
./scripts/init-backend.sh gcp-gcs prod       # For production on GCP
./scripts/init-backend.sh azure-storage prod # For production on Azure

# Terraform is automatically initialized by the backend script
```

### Plan and Apply Changes

**Development Environment:**
```bash
# Plan changes for dev
terraform plan -var-file="environments/dev.tfvars"

# Apply changes to dev
terraform apply -var-file="environments/dev.tfvars"
```

**UAT Environment:**
```bash
# Plan changes for UAT
terraform plan -var-file="environments/uat.tfvars"

# Apply changes to UAT
terraform apply -var-file="environments/uat.tfvars"
```

**Production Environment:**
```bash
# Plan changes for production
terraform plan -var-file="environments/prod.tfvars"

# Apply changes to production
terraform apply -var-file="environments/prod.tfvars"
```

### View Current State

```bash
# Show current state for specific environment
terraform show

# List all resources
terraform state list

# Get details of specific resource
terraform state show 'module.topics.confluent_kafka_topic.topics["user-events"]'
```

### Destroy Resources (Use with Caution)

```bash
# Destroy dev environment
terraform destroy -var-file="environments/dev.tfvars"

# Destroy specific resource
terraform destroy -var-file="environments/dev.tfvars" -target='module.topics.confluent_kafka_topic.topics["topic-name"]'
```

## 🔄 Environment Promotion Workflow

### Promoting from Dev to UAT

1. **Test in Development:**
   ```bash
   terraform apply -var-file="environments/dev.tfvars"
   ```

2. **Update UAT Configuration:**
   - Copy relevant changes from `config/dev/config.yaml` to `config/uat/config.yaml`
   - Adjust environment-specific settings (partitions, retention, etc.)
   - Update service account names to include "-uat" suffix

3. **Apply to UAT:**
   ```bash
   terraform plan -var-file="environments/uat.tfvars"
   terraform apply -var-file="environments/uat.tfvars"
   ```

### Promoting from UAT to Production

1. **Validate in UAT:**
   ```bash
   terraform plan -var-file="environments/uat.tfvars"
   ```

2. **Update Production Configuration:**
   - Copy validated changes from `config/uat/config.yaml` to `config/prod/config.yaml`
   - Adjust production-specific settings (higher partitions, longer retention, higher replication factor)
   - Update service account names to include "-prod" suffix

3. **Apply to Production:**
   ```bash
   terraform plan -var-file="environments/prod.tfvars"
   terraform apply -var-file="environments/prod.tfvars"
   ```

## ⚙️ Configuration Guide

This project supports two configuration approaches:

### 1. YAML-based Configuration (Traditional)
The traditional approach using environment-specific YAML files in `config/{env}/config.yaml`.

### 2. Data-driven Configuration (New)
A direct Terraform variable approach that allows you to define all resources programmatically using Terraform variables. This is ideal for:
- Programmatic resource generation
- Integration with other systems
- Dynamic configuration based on external data sources

#### Using Data-driven Configuration

Create a `.tfvars` file with your configuration:

```hcl
topics = [
  {
    name       = "topic-a"
    partitions = 10
    config = {
      "delete.retention.ms" = "10000000",
      "min.insync.replicas" = "1",
      "cleanup.policy"      = "compact",
      "max.message.bytes"   = "100"
    }
  },
  {
    name       = "topic-b"
    partitions = 10
    config = {
      "delete.retention.ms" = "10000000",
      "min.insync.replicas" = "1",
      "cleanup.policy"      = "compact", 
      "max.message.bytes"   = "100"
    }
  }
]

service_account_list = [
  "producer-sa", 
  "producer2-sa", 
  "producer3-sa", 
  "consumer-sa",
  "consumer2-sa", 
  "producer_consumer_sa",
  "producer_consumer_sa-b"
]

topics_rbac = [
  {
    topic_name = "topic-a"
    producer_sa_list = ["producer-sa", "producer3-sa"]
    consumer_sa_list = ["consumer-sa"]
    producer_and_consumer_sa_list = ["producer_consumer_sa"]
  },
  {
    topic_name = "topic-b"
    producer_sa_list = ["producer2-sa", "producer3-sa"]
    consumer_sa_list = ["consumer-sa", "consumer2-sa"]
    producer_and_consumer_sa_list = ["producer_consumer_sa-b", "producer_consumer_sa"]
  }
]
```

Then run Terraform with your data-driven configuration:

```bash
terraform plan -var-file="your-data-driven.tfvars"
terraform apply -var-file="your-data-driven.tfvars"
```

See `examples/data-driven.tfvars` for a complete example.

#### Key Benefits of Data-driven Configuration:
- **Programmatic**: Generate configurations from external systems or databases
- **Type-safe**: Leverage Terraform's type system for validation
- **Flexible**: Mix with YAML configuration (data-driven takes precedence)
- **Automated RBAC**: Automatically creates producer/consumer role bindings based on `topics_rbac`

---

### YAML Configuration Examples

### Adding New Topics

Edit the appropriate environment config file (`config/{env}/config.yaml`):

```yaml
topics:
  new-topic-name:
    partitions: 6
    config:
      "cleanup.policy": "delete"
      "retention.ms": "604800000"
      "min.insync.replicas": "2"
      "max.message.bytes": "1000000"
```

### Adding New Service Accounts

```yaml
service_accounts:
  new-service-dev:
    description: "Service account for new service in dev environment"
```

### Adding RBAC Permissions

```yaml
rbac_bindings:
  new-service-producer:
    principal_type: "service_account"
    principal_name: "new-service-dev"
    role_name: "DeveloperWrite"
    crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=new-topic-name"
```

### Adding Schemas

```yaml
schemas:
  new-schema-value:
    format: "AVRO"  # or "JSON", "PROTOBUF"
    schema_file: "confluent_metadata/schemas/new-schema-value.avsc"
```

## 🔧 Common Configurations

### Topic Configuration Options

```yaml
topics:
  example-topic:
    partitions: 12
    config:
      "cleanup.policy": "delete"                    # or "compact"
      "retention.ms": "604800000"                   # 7 days in milliseconds
      "retention.bytes": "1073741824"               # 1GB
      "segment.ms": "86400000"                      # 24 hours
      "min.insync.replicas": "2"                    # Minimum replicas for ack=all
      "max.message.bytes": "1000000"                # 1MB max message size
      "compression.type": "producer"                # or "gzip", "snappy", "lz4", "zstd"
```

### Common RBAC Roles

- `EnvironmentAdmin`: Full environment access
- `CloudClusterAdmin`: Full cluster access
- `DeveloperRead`: Read access to topics
- `DeveloperWrite`: Write access to topics
- `DeveloperManage`: Manage topics and configurations
- `ResourceOwner`: Full resource ownership

### CRN Pattern Examples

```yaml
# Environment level
crn_pattern: "crn://confluent.cloud/organization=*/environment=*"

# Cluster level  
crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*"

# Specific topic
crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=topic-name"

# All topics with prefix
crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=prefix-*"

# Consumer group
crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/group=group-name"
```

## 🐛 Troubleshooting

### Common Issues

**1. Authentication Errors**
```bash
Error: 401 Unauthorized
```
- Verify `CONFLUENT_CLOUD_API_KEY` and `CONFLUENT_CLOUD_API_SECRET` environment variables
- Ensure API key has sufficient permissions

**2. Resource Not Found**
```bash
Error: cluster lkc-xxxxx was not found
```
- Verify cluster ID in `environments/{env}.tfvars`
- Ensure cluster exists in the specified environment

**3. Schema File Not Found**
```bash
Error: file "confluent_metadata/schemas/schema-name.avsc" does not exist
```
- Verify schema file exists in the `confluent_metadata/schemas/` directory
- Check file path in configuration matches actual file location

**4. Identity Provider Issues**
```bash
Error: identity provider op-xxxxx was not found  
```
- Verify identity provider ID in configuration files
- Ensure identity provider is properly configured in Confluent Cloud

**5. Saved Plan is Stale Error**
```bash
Error: Saved plan is stale
The given plan file can no longer be applied because the state was changed
by another operation after the plan was created.
```
- **Cause**: Configuration or state changed after creating the plan file
- **Solution**: Remove old plan files and redeploy
```bash
rm -f dev.tfplan uat.tfplan prod.tfplan
./scripts/deploy.sh dev apply
```

**6. Schema Registry Authentication Issues**
```bash
Error: error validating Schema: 401 Unauthorized: Unauthorized
```
- **Cause**: Missing or incorrect Schema Registry API credentials
- **Solution**: Ensure Schema Registry API credentials are configured (separate from Kafka credentials)
```bash
# In your environments/{env}.tfvars file:
schema_registry_api_key    = "YOUR_SCHEMA_REGISTRY_API_KEY"
schema_registry_api_secret = "YOUR_SCHEMA_REGISTRY_API_SECRET"
schema_registry_rest_endpoint = "https://psrc-xxxxx.region.provider.confluent.cloud"
```
- Create Schema Registry API keys in Confluent Cloud Console → Schema Registry → API Keys

**8. RBAC Permission Issues**
```bash
Error: error creating Role Binding: 403 Forbidden: Forbidden Access
```
- **Cause**: Either API key lacks permissions OR provider cache hasn't refreshed after permission updates
- **Required Permissions**: OrganizationAdmin OR EnvironmentAdmin for target environment
- **Diagnosis**: 
```bash
# Check which API key is being used
echo "Current API Key: $CONFLUENT_CLOUD_API_KEY"

# Verify API key permissions in Confluent Cloud Console:
# Administration → Access → API Keys → Find your key → Check roles
```
- **Solutions**:
```bash
# Option 1: Clear provider cache (if permissions were recently updated)
rm -rf .terraform/providers
terraform init
terraform apply -var-file="environments/{env}.tfvars"

# Option 2: Upgrade existing API key permissions in Confluent Cloud Console
# 1. Go to Administration → Access → API Keys  
# 2. Find your API key and verify service account has OrganizationAdmin or EnvironmentAdmin role

# Option 3: Create new API key with proper permissions
# 1. Create service account with OrganizationAdmin role
# 2. Generate API key for that service account  
# 3. Update environment variables
export CONFLUENT_CLOUD_API_KEY="new-admin-api-key"
export CONFLUENT_CLOUD_API_SECRET="new-admin-api-secret"

# Option 4: Temporarily skip RBAC creation for testing
# Comment out RBAC module in main.tf to test other components first
```

**Note**: If you recently updated API key permissions, always clear the provider cache first before troubleshooting further.

**7. State Management and Drift Issues**

These are common issues when your Terraform state doesn't match the actual infrastructure:

**7a. Resource Already Exists Error**
```bash
Error: error creating Service Account "my-service": 409 Conflict: 
Unable to create service account for organization: Service name is already in use.
```
- **Cause**: Resource exists in Confluent Cloud but not in Terraform state (state drift)
- **Solution**: Import existing resources into Terraform state
```bash
# Use our automated import script
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
./scripts/import-confluent-resources.sh dev
```

**7b. Empty Destroy Operations**
```bash
terraform destroy -var-file="environments/dev.tfvars"
# No resources to destroy despite having infrastructure
```
- **Cause**: Resources exist in cloud but Terraform doesn't know about them
- **Solution**: Same as above - import resources first, then destroy will work properly

**7c. State Contamination (Wrong Resources in State)**
```bash
Error: error reading Kafka Topic: 403 Forbidden: API key is not allowed to access cluster
```
- **Cause**: Environment state contains resources from other environments (e.g., DEV resources in UAT state)
- **Diagnosis**: Check what's in your state
```bash
terraform state list
# Look for resources that don't belong in this environment
```
- **Solution**: Remove foreign resources from state
```bash
# Example: Remove DEV resources from UAT state
terraform state rm 'module.topics.confluent_kafka_topic.topics["dev-topic-name"]'
terraform state rm 'module.service_accounts.confluent_service_account.service_accounts["dev-service"]'
```

**7d. State File Corruption or Missing**
```bash
Error: Failed to load state: state file has no lineage
```
- **Cause**: State file is corrupted or missing
- **Solutions**:
```bash
# Option 1: Restore from backup
cp states/dev/terraform.tfstate.backup states/dev/terraform.tfstate

# Option 2: Reinitialize and import everything
rm -rf .terraform states/dev/terraform.tfstate*
./scripts/init-backend.sh local dev
./scripts/import-confluent-resources.sh dev
```

**7e. State Lock Issues**
```bash
Error: Error acquiring the state lock
```
- **Cause**: Another Terraform operation is running or was interrupted
- **Solutions**:
```bash
# Option 1: Wait and retry (if another operation is genuinely running)

# Option 2: Force unlock (only if you're sure no other operation is running)
terraform force-unlock LOCK_ID

# Option 3: For local backends, remove lock file
rm .terraform.lock.info
```

**7f. State Version Mismatch**
```bash
Error: state snapshot was created by Terraform v1.x, but this is v1.y
```
- **Cause**: State was created with different Terraform version
- **Solution**: Upgrade state format
```bash
terraform init -upgrade
```

### State Recovery Commands

```bash
# Backup current state before making changes
cp states/dev/terraform.tfstate states/dev/terraform.tfstate.manual-backup-$(date +%Y%m%d_%H%M%S)

# List all resources in state
terraform state list

# Show detailed info about specific resource
terraform state show 'module.topics.confluent_kafka_topic.topics["topic-name"]'

# Remove specific resource from state (doesn't destroy actual resource)
terraform state rm 'module.topics.confluent_kafka_topic.topics["topic-name"]'

# Import existing resource into state
terraform import -var-file="environments/dev.tfvars" \
  'module.topics.confluent_kafka_topic.topics["topic-name"]' \
  lkc-cluster-id/topic-name

# Refresh state to match actual infrastructure
terraform refresh -var-file="environments/dev.tfvars"

# Replace corrupted resource in state (removes and re-imports)
terraform apply -replace='module.topics.confluent_kafka_topic.topics["topic-name"]' \
  -var-file="environments/dev.tfvars"
```

### State Management Best Practices

To avoid state issues in the future:

**✅ Prevention Strategies:**
```bash
# 1. Always backup state before major changes
cp states/dev/terraform.tfstate states/dev/terraform.tfstate.pre-change-backup

# 2. Use import script for existing resources before first deploy
./scripts/import-confluent-resources.sh dev

# 3. Verify state consistency regularly
terraform plan -var-file="environments/dev.tfvars"
# Should show "No changes" if state matches reality

# 4. Don't manually create resources that Terraform should manage
# Always add them to configuration first, then apply

# 5. Use separate state files per environment (already configured)
./scripts/init-backend.sh local dev   # dev state: states/dev/
./scripts/init-backend.sh local uat   # uat state: states/uat/
./scripts/init-backend.sh local prod  # prod state: states/prod/
```

**🔧 Recovery Workflow:**
```bash
# Step 1: Assess the situation
terraform state list
terraform plan -var-file="environments/dev.tfvars"

# Step 2: Backup current state
cp states/dev/terraform.tfstate states/dev/terraform.tfstate.recovery-backup

# Step 3: Fix the issue (choose appropriate method above)
# - Import missing resources
# - Remove foreign resources  
# - Restore from backup
# - Re-import everything

# Step 4: Verify fix
terraform plan -var-file="environments/dev.tfvars"
# Should show expected changes only

# Step 5: Apply if needed
terraform apply -var-file="environments/dev.tfvars"
```

### Debugging Commands

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply -var-file="environments/dev.tfvars"

# Validate configuration syntax
terraform validate

# Format configuration files
terraform fmt -recursive

# Check configuration for potential issues
terraform plan -var-file="environments/dev.tfvars" -detailed-exitcode
```

### 🗂️ Organized State Management

This project automatically organizes Terraform state files by environment for better organization and team collaboration:

```
states/
├── dev/                    # Development environment
│   ├── terraform.tfstate   # Current state
│   ├── terraform.tfstate.backup # Auto-backup
│   └── *.tfplan           # Plan files
├── uat/                    # UAT environment
└── prod/                   # Production environment
```

**Benefits:**
- ✅ **Clean Root Directory**: No state files cluttering your project
- ✅ **Environment Isolation**: Each environment has separate state files
- ✅ **Easy Backup**: Simple to backup or archive states by environment
- ✅ **Team Collaboration**: Clearer state management across teams
- ✅ **Automatic Organization**: Scripts handle file organization

**Backend Paths:**
- **Local**: `./states/{env}/terraform.tfstate`
- **AWS S3**: `confluent-kafka/{env}/terraform.tfstate`
- **GCP GCS**: `confluent-kafka/{env}/default.tfstate`
- **Azure Storage**: `confluent-kafka/{env}/terraform.tfstate`

### State Management Commands

```bash
# Import existing resource
terraform import -var-file="environments/dev.tfvars" 'module.topics.confluent_kafka_topic.topics["topic-name"]' lkc-xxxxx/topic-name

# Remove resource from state (without destroying)
terraform state rm 'module.topics.confluent_kafka_topic.topics["topic-name"]'

# Move resource in state
terraform state mv 'module.topics.confluent_kafka_topic.topics["old-name"]' 'module.topics.confluent_kafka_topic.topics["new-name"]'

# View current state location
terraform show -json | jq -r '.terraform_version, .serial'
```

## 📚 Additional Resources

- [Confluent Terraform Provider Documentation](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs)
- [Confluent Cloud RBAC Documentation](https://docs.confluent.io/cloud/current/access-management/access-control/rbac/overview.html)
- [Schema Registry Documentation](https://docs.confluent.io/platform/current/schema-registry/index.html)
- [Kafka Topic Configuration](https://kafka.apache.org/documentation/#topicconfigs)

## 📊 State Management

### Viewing Current Resources

To see what resources are currently managed by Terraform:

```bash
# List all resources in state
terraform state list

# Show detailed information about a specific resource
terraform state show 'module.topics.confluent_kafka_topic.topics["user-events"]'
```

### State Location

Your Terraform state is stored at: `./states/dev/terraform.tfstate`

For comprehensive state management documentation, see: [docs/TERRAFORM_STATE_MANAGEMENT.md](docs/TERRAFORM_STATE_MANAGEMENT.md)

### Importing Existing Resources

If you have existing Confluent Cloud resources that aren't tracked in Terraform state, use the automated import script:

```bash
# Set credentials
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# Import all existing resources for any environment
./scripts/import-confluent-resources.sh dev   # Development
./scripts/import-confluent-resources.sh uat   # UAT  
./scripts/import-confluent-resources.sh prod  # Production
```

This script automatically:
- 🔍 **Discovers existing resources** from your Confluent Cloud account
- 📋 **Reads expected configuration** from your JSON files  
- 🔄 **Imports resources** into Terraform state
- ✅ **Resolves "already exists" errors** during deployments

**Common scenarios:**
- Getting "409 Conflict: Service name is already in use" errors
- Running `terraform destroy` shows no resources to destroy
- Resources exist in Confluent Cloud but not in Terraform state
- Moving from manual resource creation to Infrastructure as Code

For detailed documentation: [docs/IMPORTING_EXISTING_RESOURCES.md](docs/IMPORTING_EXISTING_RESOURCES.md)

## 🤝 Contributing

1. Make changes to the appropriate environment configuration files
2. Test changes in development environment first
3. Follow the promotion workflow for UAT and production
4. Document any new configurations or troubleshooting steps

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details. 