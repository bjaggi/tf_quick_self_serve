# 🏗️ Backend Management Guide

This Terraform solution supports multiple backend configurations for flexible state management across different environments and cloud providers. Choose the backend that best fits your team collaboration needs and infrastructure.

## 🗂️ Organized State Structure

This solution automatically organizes Terraform state files by environment for better project organization:

```
states/
├── dev/                    # Development environment states
│   ├── terraform.tfstate   # Current state file
│   ├── terraform.tfstate.backup # Previous state backup
│   └── *.tfplan           # Plan files from terraform plan
├── uat/                    # UAT environment states
├── prod/                   # Production environment states
└── README.md              # State organization documentation
```

> Recommendation: Keep `states/` for local-only dev and backups; use remote backends for shared envs.

**Key Benefits:**
- ✅ **Clean Root Directory**: No `.tfstate` files cluttering your project
- ✅ **Environment Isolation**: Each environment has its own state directory
- ✅ **Consistent Paths**: Same structure for local and remote backends
- ✅ **Easy Backup**: Simple to backup states by environment
- ✅ **Team Collaboration**: Clear state management across different environments

## 🏛️ Supported Backend Types

| Backend | Use Case | Team Collaboration | State Locking | State Path | Setup Complexity |
|---------|----------|-------------------|---------------|------------|------------------|
| **Local** | Development, Testing | ❌ | ❌ | `states/{env}/` | ⭐ |
| **AWS S3** | Production on AWS | ✅ | ❌ (Simplified) | `confluent-kafka/{env}/` | ⭐⭐ |
| **GCP Cloud Storage** | Production on GCP | ✅ | ✅ (Built-in) | `confluent-kafka/{env}/` | ⭐⭐⭐ |
| **Azure Storage** | Production on Azure | ✅ | ✅ (Built-in) | `confluent-kafka/{env}/` | ⭐⭐⭐ |

## 🚀 Quick Start

### Initialize Backend

```bash
# Initialize backend for development (local)
./scripts/init-backend.sh local dev

# Initialize backend for production (AWS S3)
./scripts/init-backend.sh aws-s3 prod

# Initialize backend for production (GCP Cloud Storage)
./scripts/init-backend.sh gcp-gcs prod

# Initialize backend for production (Azure Storage)
./scripts/init-backend.sh azure-storage prod
```

### Deploy After Backend Setup

```bash
# Deploy to the environment
./scripts/deploy.sh <environment> <action>

# Examples:
./scripts/deploy.sh dev apply
./scripts/deploy.sh prod plan
```

## 📚 Detailed Backend Configuration

### Local Backend

**Use case:** Individual development, testing, proof of concepts

**Setup:**
```bash
./scripts/init-backend.sh local dev
```

**Benefits:**
- ✅ Simple setup, no external dependencies
- ✅ Fast state operations
- ✅ No additional costs
- ✅ Full control over state file

**Limitations:**
- ❌ No team collaboration (state not shared)
- ❌ No state locking (concurrent execution issues)
- ❌ Risk of state file loss if machine fails
- ❌ No versioning or backup built-in

**Recommended for:**
- Individual development
- Proof of concepts
- Testing and experimentation
- CI/CD environments with ephemeral workers

---

### AWS S3 Backend

**Use case:** Production environments on AWS with team collaboration

**Prerequisites:**
1. AWS CLI configured or IAM role with appropriate permissions
2. S3 bucket for state storage with versioning enabled
3. Appropriate IAM permissions for Terraform execution role

**Setup:**

1. **Quick setup with example script:**
```bash
# Run the example setup script
./examples/backends/prod-aws.sh
```

2. **Manual setup:**
```bash
# Create S3 bucket
aws s3 mb s3://your-terraform-state-bucket --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Update backend configuration
sed -i 's/your-terraform-state-bucket/your-actual-bucket-name/g' tf_state_externalized/aws-s3.tf

# Initialize backend
# This will create state path: confluent-kafka/prod/terraform.tfstate
./scripts/init-backend.sh aws-s3 prod
```

**Required IAM Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket",
        "arn:aws:s3:::your-terraform-state-bucket/*"
      ]
    }
  ]
}
```

**Benefits:**
- ✅ Simple setup, just S3 bucket required
- ✅ Team collaboration with shared state
- ✅ Versioning and backup through S3  
- ✅ Encryption at rest and in transit
- ✅ Cost-effective (~$0.50/month for typical usage)
- ✅ Integration with AWS IAM

**⚠️ Important:** No state locking enabled - avoid concurrent terraform runs

---

### GCP Cloud Storage Backend

**Use case:** Production environments on GCP with team collaboration

**Prerequisites:**
1. GCP project with Cloud Storage API enabled
2. Service account with appropriate permissions
3. GCS bucket for state storage with versioning enabled
4. GCP credentials configured

**Setup:**

1. **Quick setup with example script:**
```bash
# Run the example setup script
./examples/backends/prod-gcp.sh
```

2. **Manual setup:**
```bash
# Create GCS bucket
gsutil mb -p your-project-id -c STANDARD -l us-central1 gs://your-terraform-state-bucket

# Enable versioning
gsutil versioning set on gs://your-terraform-state-bucket

# Create service account
gcloud iam service-accounts create terraform-state \
  --display-name="Terraform State Management"

# Grant permissions
gcloud projects add-iam-policy-binding your-project-id \
  --member="serviceAccount:terraform-state@your-project-id.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Update backend configuration
sed -i 's/your-terraform-state-bucket/your-actual-bucket-name/g' tf_state_externalized/gcp-gcs.tf

# Initialize backend
./scripts/init-backend.sh gcp-gcs prod
```

**Required Permissions:**
- `Storage Object Admin` (on the bucket)
- `Storage Legacy Bucket Reader` (on the bucket)

**Benefits:**
- ✅ Team collaboration with shared state
- ✅ Built-in state locking (no additional resources needed)
- ✅ Versioning and backup through GCS
- ✅ Encryption at rest and in transit
- ✅ Integration with GCP IAM
- ✅ Cost-effective storage

---

### Azure Storage Backend

**Use case:** Production environments on Azure with team collaboration

**Prerequisites:**
1. Azure subscription with Storage Account
2. Service Principal or Managed Identity with appropriate permissions
3. Storage Account with container for state storage
4. Azure credentials configured

**Setup:**

1. **Quick setup with example script:**
```bash
# Run the example setup script
./examples/backends/prod-azure.sh
```

2. **Manual setup:**
```bash
# Create resource group
az group create --name terraform-state-rg --location "East US"

# Create storage account
az storage account create \
  --name yourstorageaccount \
  --resource-group terraform-state-rg \
  --location "East US" \
  --sku Standard_LRS \
  --kind StorageV2

# Create container
az storage container create \
  --name terraform-state \
  --account-name yourstorageaccount

# Update backend configuration
sed -i 's/your-resource-group/terraform-state-rg/g' tf_state_externalized/azure-storage.tf
sed -i 's/yourstorageaccount/your-actual-storage-account/g' tf_state_externalized/azure-storage.tf

# Initialize backend
./scripts/init-backend.sh azure-storage prod
```

**Required Permissions:**
- `Storage Blob Data Contributor` (on the storage account or container)
- `Reader` (on the resource group)

**Benefits:**
- ✅ Team collaboration with shared state
- ✅ Built-in state locking (no additional resources needed)
- ✅ Versioning through Azure Storage
- ✅ Encryption at rest and in transit
- ✅ Integration with Azure RBAC
- ✅ Geo-redundant storage options

## 🔄 Backend Migration

### Migrating from Local to Remote Backend

1. **Backup current state:**
```bash
cp terraform.tfstate terraform.tfstate.backup
```

2. **Initialize new backend:**
```bash
./scripts/init-backend.sh aws-s3 prod
```

3. **Migrate state:**
```bash
terraform init -migrate-state
```

4. **Verify migration:**
```bash
terraform show
```

### Changing Remote Backends

1. **Export current state:**
```bash
terraform state pull > terraform-state-backup.json
```

2. **Initialize new backend:**
```bash
./scripts/init-backend.sh gcp-gcs prod
```

3. **Import state to new backend:**
```bash
terraform state push terraform-state-backup.json
```

## 🛠️ Backend Management Commands

### Initialize Backend
```bash
# Initialize backend for specific environment
./scripts/init-backend.sh <backend-type> <environment>

# Examples:
./scripts/init-backend.sh local dev
./scripts/init-backend.sh aws-s3 prod
./scripts/init-backend.sh gcp-gcs uat
./scripts/init-backend.sh azure-storage prod
```

### Verify Backend Configuration
```bash
# Show current backend configuration
cat backend.tf

# Verify Terraform can access backend
terraform init -backend=false
terraform workspace show
```

### State Management
```bash
# List all resources in state
terraform state list

# Show current state
terraform show

# Pull state to local file
terraform state pull > current-state.json

# Push state from local file
terraform state push current-state.json
```

## 🔧 Advanced Configuration

### Environment-Specific State Paths

The backend initialization script automatically configures environment-specific state paths:

- **AWS S3:** `confluent-kafka/{environment}/terraform.tfstate`
- **GCP GCS:** `confluent-kafka/{environment}/default.tfstate`
- **Azure Storage:** `confluent-kafka-{environment}.terraform.tfstate`
- **Local:** `terraform-{environment}.tfstate`

### Custom Backend Configuration

You can customize backend configurations by editing the files in the `tf_state_externalized/` directory:

```bash
# Edit AWS S3 backend configuration
vi tf_state_externalized/aws-s3.tf

# Edit GCP GCS backend configuration
vi tf_state_externalized/gcp-gcs.tf

# Edit Azure Storage backend configuration
vi tf_state_externalized/azure-storage.tf

# Edit Local backend configuration
vi tf_state_externalized/local.tf
```

### Multiple Environments with Same Backend

For organizations using the same backend for multiple environments:

```bash
# Production
./scripts/init-backend.sh aws-s3 prod

# UAT (using same S3 bucket but different path)
./scripts/init-backend.sh aws-s3 uat

# Development (can use local for faster iteration)
./scripts/init-backend.sh local dev
```

## 🐛 Troubleshooting

### Common Issues

#### Backend Configuration Not Found
```bash
Error: Backend configuration not found!
```
**Solution:** Run the backend initialization script:
```bash
./scripts/init-backend.sh <backend-type> <environment>
```

#### AWS S3 Access Denied
```bash
Error: AccessDenied: Access Denied
```
**Solutions:**
- Verify AWS credentials: `aws sts get-caller-identity`
- Check IAM permissions for S3 bucket
- Ensure bucket exists and is in the correct region

#### GCP Cloud Storage Permission Denied
```bash
Error: storage: permission denied
```
**Solutions:**
- Verify GCP credentials: `gcloud auth list`
- Check service account permissions
- Ensure bucket exists and is accessible

#### Azure Storage Authorization Failed
```bash
Error: authorization failed
```
**Solutions:**
- Verify Azure credentials: `az account show`
- Check service principal permissions
- Ensure storage account and container exist

#### State Locking Issues
```bash
Error: state lock could not be acquired
```
**Solutions:**
- Wait for current operation to complete
- Force unlock (use with caution): `terraform force-unlock <lock-id>`
- Check storage account permissions

### Debug Commands

```bash
# Validate backend configuration
terraform init -backend=false

# Show backend configuration
terraform version
terraform providers

# Test cloud provider credentials
aws sts get-caller-identity  # AWS
gcloud auth list            # GCP
az account show            # Azure

# Check state file location
terraform state pull | head -5
```

## 🏗️ CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Deploy
on:
  push:
    branches: [main]
    
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
    
    - name: Initialize Backend
      run: ./scripts/init-backend.sh aws-s3 prod
    
    - name: Deploy Infrastructure
      run: ./scripts/deploy.sh prod apply
```

### GitLab CI Example

```yaml
deploy:
  stage: deploy
  image: hashicorp/terraform:1.0
  before_script:
    - apk add --no-cache bash aws-cli
  script:
    - ./scripts/init-backend.sh aws-s3 prod
    - ./scripts/deploy.sh prod apply
  only:
    - main
```

## 📊 Cost Optimization

### Backend Storage Costs

| Backend | Storage Cost | Locking Cost | Operations Cost |
|---------|-------------|-------------|-----------------|
| **Local** | Free | N/A | Free |
| **AWS S3** | $0.023/GB/month | N/A (No locking) | $0.0004/1000 requests |
| **GCP GCS** | $0.020/GB/month | Free | $0.05/10,000 operations |
| **Azure Storage** | $0.0184/GB/month | Free | $0.0004/10,000 transactions |

### Cost Optimization Tips

1. **Use lifecycle policies** to archive old state versions
2. **Enable compression** on storage accounts where available
3. **Use regional storage** instead of multi-region for non-production
4. **Monitor state file sizes** and clean up unused resources
5. **Use local backends** for development to avoid cloud storage costs

## 📚 Additional Resources

- [Terraform Backend Documentation](https://www.terraform.io/docs/language/settings/backends/index.html)
- [AWS S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [GCP GCS Backend](https://www.terraform.io/docs/language/settings/backends/gcs.html)
- [Azure Storage Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Terraform State Management Best Practices](https://www.terraform.io/docs/language/state/index.html) 