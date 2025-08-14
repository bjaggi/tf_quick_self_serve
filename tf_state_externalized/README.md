# Terraform State Backend Configurations

This directory contains backend configuration templates for managing Terraform state across different cloud providers and environments.

## Available Backends

### 🏠 Local Backend (`local.tf`)
- **Purpose**: Development and testing
- **Storage**: Local filesystem
- **Cost**: Free
- **Collaboration**: Single user only
- **State File**: `terraform-{environment}.tfstate`

### ☁️ AWS S3 Backend (`aws-s3.tf`) 
- **Purpose**: Production environments
- **Storage**: AWS S3 with DynamoDB locking
- **Cost**: Minimal S3 storage costs
- **Collaboration**: Multi-user with state locking
- **State File**: `confluent-kafka/{environment}/terraform.tfstate`

### 🌐 GCP Cloud Storage Backend (`gcp-gcs.tf`)
- **Purpose**: Production environments on GCP
- **Storage**: Google Cloud Storage
- **Cost**: Minimal GCS storage costs  
- **Collaboration**: Multi-user with state locking
- **State File**: `confluent-kafka-{environment}.terraform.tfstate`

### 🔵 Azure Storage Backend (`azure-storage.tf`)
- **Purpose**: Production environments on Azure
- **Storage**: Azure Storage Account
- **Cost**: Minimal blob storage costs
- **Collaboration**: Multi-user with state locking
- **State File**: `confluent-kafka-{environment}.terraform.tfstate`

## Quick Setup

Use the example scripts in `examples/backends/` to quickly set up your preferred backend:

```bash
# AWS S3 Backend
./examples/backends/prod-aws.sh

# GCP Cloud Storage Backend  
./examples/backends/prod-gcp.sh

# Azure Storage Backend
./examples/backends/prod-azure.sh

# Local Backend (development)
./examples/backends/dev-local.sh
```

## Manual Configuration

1. **Choose your backend** by editing the appropriate `.tf` file
2. **Update placeholder values** with your actual resource names
3. **Initialize the backend** using `./scripts/init-backend.sh`

### Example: AWS S3 Setup

```bash
# Edit the S3 backend configuration
vi tf_state_externalized/aws-s3.tf

# Update these values:
# - your-terraform-state-bucket -> your-actual-bucket-name  
# - your-aws-region -> us-west-2
# - your-dynamodb-table -> terraform-state-lock

# Initialize the backend
./scripts/init-backend.sh aws-s3 prod
```

## Backend Features Comparison

| Feature | Local | AWS S3 | GCP GCS | Azure Storage |
|---------|-------|--------|---------|---------------|
| **Multi-user** | ❌ | ✅ | ✅ | ✅ |
| **State Locking** | ❌ | ✅ | ✅ | ✅ |
| **Versioning** | ❌ | ✅ | ✅ | ✅ |
| **Encryption** | ❌ | ✅ | ✅ | ✅ |  
| **Cost** | Free | ~$0.01/month | ~$0.01/month | ~$0.01/month |
| **Setup Complexity** | None | Medium | Medium | Medium |

## Environment Recommendations

- **Development**: Local backend for simplicity
- **UAT/Staging**: Cloud backend for team collaboration
- **Production**: Cloud backend with versioning and encryption

## State Management Best Practices

1. **Always backup state** before major changes
2. **Use state locking** to prevent concurrent modifications
3. **Enable versioning** on cloud storage backends
4. **Encrypt state files** containing sensitive data
5. **Restrict access** to state storage using IAM policies

## Troubleshooting

### Backend Migration
```bash  
# Pull current state
terraform state pull > backup-state.json

# Reconfigure backend
terraform init -reconfigure

# Verify state integrity
terraform plan
```

### State Recovery
```bash
# Restore from backup
terraform state push backup-state.json

# Import missing resources
terraform import confluent_kafka_topic.example topic-name
```

For detailed setup instructions, see [BACKEND_MANAGEMENT.md](../BACKEND_MANAGEMENT.md).