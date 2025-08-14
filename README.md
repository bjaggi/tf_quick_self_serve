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
kafka_rest_endpoint = "https://pkc-your-cluster.region.provider.confluent.cloud:443"
kafka_api_key    = "your-kafka-api-key"
kafka_api_secret = "your-kafka-api-secret"
```

**For UAT:**
```bash
# Edit environments/uat.tfvars
environment        = "uat"
cluster_id        = "lkc-your-uat-cluster-id"
environment_id    = "env-your-uat-environment-id"
kafka_rest_endpoint = "https://pkc-your-cluster.region.provider.confluent.cloud:443"
kafka_api_key    = "your-kafka-api-key"
kafka_api_secret = "your-kafka-api-secret"
schema_registry_id = "lsrc-your-schema-registry-id"  # Optional
```

**For Production:**
```bash
# Edit environments/prod.tfvars
environment        = "prod"
cluster_id        = "lkc-your-prod-cluster-id"
environment_id    = "env-your-prod-environment-id"
schema_registry_id = "lsrc-your-schema-registry-id"  # Optional
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

## 🤝 Contributing

1. Make changes to the appropriate environment configuration files
2. Test changes in development environment first
3. Follow the promotion workflow for UAT and production
4. Document any new configurations or troubleshooting steps

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details. 