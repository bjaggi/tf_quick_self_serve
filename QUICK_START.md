# Quick Start Guide

Get up and running with Confluent Kafka Infrastructure as Code in 5 minutes!

## 🏃‍♂️ Quick Setup

### 1. Set Environment Variables
```bash
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
```

### 2. Update Resource IDs
Edit `environments/dev.tfvars`:
```hcl
environment        = "dev"
cluster_id        = "lkc-your-cluster-id"      # ← Change this
environment_id    = "env-your-environment-id"  # ← Change this
schema_registry_id = "lsrc-your-sr-id"         # ← Change this (optional)
```

### 3. Initialize Backend
```bash
# Initialize backend (local is good for development)
# This creates the organized states/dev/ directory structure
./scripts/init-backend.sh local dev
```

### 4A. Fresh Deployment (No Existing Resources)
```bash
# Deploy using the convenient deployment script
# State files will be stored in states/dev/terraform.tfstate
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply
```

### 4B. Import Existing Resources (If You Have Them)
```bash
# If you get "already exists" errors or have existing Confluent Cloud resources:
./scripts/import-confluent-resources.sh dev

# Then deploy normally (will only create missing resources)
./scripts/deploy.sh dev apply
```

**💡 Pro Tip**: Always run the import script first if you're unsure whether resources exist. It's safe to run and will only import what's needed!

## 🎯 What Gets Created

With the default configuration, you'll get:

- **3 Kafka Topics**: `user-events`, `order-events`, `payment-events`
- **3 Service Accounts**: For each microservice
- **1 Identity Pool**: For your development team
- **7 RBAC Bindings**: Proper read/write permissions
- **3 Schemas**: AVRO schemas for each event type

## 🔧 Customizing Your Setup

### Add a New Topic
Edit `config/dev/config.yaml`:
```yaml
topics:
  my-new-topic:
    partitions: 6
    config:
      "cleanup.policy": "delete"
      "retention.ms": "604800000"  # 7 days
```

### Add a New Service Account
```yaml
service_accounts:
  my-service-dev:
    description: "Service account for my service"
```

### Add RBAC Permissions
```yaml
rbac_bindings:
  my-service-producer:
    principal_type: "service_account"
    principal_name: "my-service-dev"
    role_name: "DeveloperWrite"
    crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=my-new-topic"
```

## 🚀 Promote to Higher Environments

1. **Copy your working config** from `config/dev/config.yaml` to `config/uat/config.yaml`
2. **Update environment-specific settings** (more partitions, longer retention, etc.)
3. **Update service account names** (change `-dev` to `-uat`)
4. **Deploy to UAT**:
   ```bash
   ./scripts/deploy.sh uat plan
   ./scripts/deploy.sh uat apply
   ```

## 📊 View What You Created

```bash
# See all resources
terraform state list

# Get topic details
terraform show 'module.topics.confluent_kafka_topic.topics["user-events"]'

# Show all outputs
terraform output
```

## 🆘 Need Help?

- **Authentication errors**: Check your API key/secret environment variables
- **Resource not found**: Verify your cluster/environment IDs in the `.tfvars` file
- **Schema errors**: Make sure schema files exist in the `confluent_metadata/schemas/` directory
- **Cloud provider errors** (az login, aws configure): Use `./scripts/setup-dev.sh` or comment out unused providers in `terraform.tf`

See the full [README.md](README.md) for comprehensive documentation.

## 🎉 Success!

You now have a fully managed Kafka infrastructure! Your developers can focus on building applications while you manage the infrastructure through simple YAML configuration files. 