# 🔐 Secret Management Guide

This Terraform solution supports multiple secret management backends to securely handle Confluent Cloud API credentials. Choose the approach that best fits your security requirements and infrastructure.

## 🎯 Supported Secret Backends

| Backend | Use Case | Security Level | Setup Complexity |
|---------|----------|----------------|------------------|
| **Environment Variables** | Development, CI/CD | ⭐⭐ | Low |
| **AWS Secrets Manager** | Production on AWS | ⭐⭐⭐⭐⭐ | Medium |
| **Azure Key Vault** | Production on Azure | ⭐⭐⭐⭐⭐ | Medium |
| **HashiCorp Vault** | Enterprise, Multi-cloud | ⭐⭐⭐⭐⭐ | High |
| **Terraform Cloud** | Terraform Cloud/Enterprise | ⭐⭐⭐⭐ | Low |

## 🚀 Quick Setup

### 1. Environment Variables (Default)

**Best for:** Development, testing, CI/CD pipelines

```bash
# Set environment variables
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"

# Configure in tfvars
secret_backend = "environment_variables"

# Deploy
./scripts/deploy.sh dev apply
```

### 2. AWS Secrets Manager

**Best for:** Production on AWS, enterprise security

```bash
# Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "confluent-cloud-credentials-prod" \
  --description "Confluent Cloud API credentials for production" \
  --secret-string '{"api_key":"your-api-key","api_secret":"your-api-secret"}'

# Configure in tfvars
secret_backend = "aws_secrets_manager"
aws_secret_name = "confluent-cloud-credentials-prod"

# Deploy (AWS credentials must be configured)
./scripts/deploy.sh prod apply
```

### 3. Azure Key Vault

**Best for:** Production on Azure, enterprise security

```bash
# Create secrets in Azure Key Vault
az keyvault secret set --vault-name "your-keyvault" --name "confluent-api-key" --value "your-api-key"
az keyvault secret set --vault-name "your-keyvault" --name "confluent-api-secret" --value "your-api-secret"

# Configure in tfvars
secret_backend = "azure_keyvault"
azure_keyvault_name = "your-keyvault"
azure_resource_group_name = "your-resource-group"

# Deploy (Azure credentials must be configured)
./scripts/deploy.sh prod apply
```

### 4. HashiCorp Vault

**Best for:** Enterprise environments, multi-cloud

```bash
# Store secrets in Vault
vault kv put secret/confluent/prod api_key="your-api-key" api_secret="your-api-secret"

# Configure in tfvars
secret_backend = "hashicorp_vault"
vault_secret_path = "secret/confluent/prod"

# Deploy (Vault authentication must be configured)
./scripts/deploy.sh prod apply
```

### 5. Terraform Cloud

**Best for:** Terraform Cloud/Enterprise users

```bash
# In Terraform Cloud workspace, add sensitive variables:
# - terraform_cloud_api_key (sensitive)
# - terraform_cloud_api_secret (sensitive)

# Configure in tfvars
secret_backend = "terraform_cloud"

# Deploy through Terraform Cloud
```

## 📚 Detailed Configuration Guide

### Environment Variables

Create or update your `.tfvars` file:

```hcl
# environments/dev.tfvars
secret_backend = "environment_variables"
```

Set environment variables:
```bash
export CONFLUENT_CLOUD_API_KEY="your-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-api-secret"
```

**Pros:**
- Simple setup
- Works well in CI/CD
- No external dependencies

**Cons:**
- Less secure for production
- Credentials visible in process environment
- Manual rotation required

### AWS Secrets Manager

#### Prerequisites
1. AWS CLI configured or IAM role with appropriate permissions
2. Permissions to read from Secrets Manager

#### Setup

1. **Create the Secret:**
```bash
aws secretsmanager create-secret \
  --name "confluent-cloud-credentials-prod" \
  --description "Confluent Cloud API credentials" \
  --secret-string '{"api_key":"your-key","api_secret":"your-secret"}'
```

2. **Configure Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:region:account:secret:confluent-cloud-credentials-*"
    }
  ]
}
```

3. **Update .tfvars:**
```hcl
secret_backend  = "aws_secrets_manager"
aws_secret_name = "confluent-cloud-credentials-prod"
```

**Pros:**
- Enterprise-grade security
- Automatic rotation support
- Fine-grained access control
- Audit logging

**Cons:**
- AWS-specific
- Additional cost
- Requires AWS credentials

### Azure Key Vault

#### Prerequisites
1. Azure CLI configured or managed identity
2. Key Vault with appropriate access policies

#### Setup

1. **Create Key Vault (if needed):**
```bash
az keyvault create \
  --name "your-keyvault" \
  --resource-group "your-rg" \
  --location "eastus"
```

2. **Add Secrets:**
```bash
az keyvault secret set \
  --vault-name "your-keyvault" \
  --name "confluent-api-key" \
  --value "your-api-key"

az keyvault secret set \
  --vault-name "your-keyvault" \
  --name "confluent-api-secret" \
  --value "your-api-secret"
```

3. **Set Access Policy:**
```bash
az keyvault set-policy \
  --name "your-keyvault" \
  --object-id "your-object-id" \
  --secret-permissions get
```

4. **Update .tfvars:**
```hcl
secret_backend               = "azure_keyvault"
azure_keyvault_name         = "your-keyvault"
azure_resource_group_name   = "your-resource-group"
azure_api_key_secret_name   = "confluent-api-key"
azure_api_secret_secret_name = "confluent-api-secret"
```

**Pros:**
- Enterprise-grade security
- Azure-native integration
- Fine-grained access control
- Audit logging

**Cons:**
- Azure-specific
- Additional cost
- Requires Azure credentials

### HashiCorp Vault

#### Prerequisites
1. Vault cluster accessible from Terraform execution environment
2. Vault authentication configured
3. Appropriate policies for reading secrets

#### Setup

1. **Store Secrets:**
```bash
vault kv put secret/confluent/prod \
  api_key="your-api-key" \
  api_secret="your-api-secret"
```

2. **Create Policy:**
```hcl
path "secret/data/confluent/*" {
  capabilities = ["read"]
}
```

3. **Configure Authentication:**
```bash
# Option 1: Token
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_TOKEN="your-token"

# Option 2: AppRole
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_ROLE_ID="your-role-id"
export VAULT_SECRET_ID="your-secret-id"
```

4. **Update .tfvars:**
```hcl
secret_backend    = "hashicorp_vault"
vault_secret_path = "secret/confluent/prod"
```

**Pros:**
- Multi-cloud support
- Advanced secret management features
- Dynamic secrets support
- Comprehensive audit logging

**Cons:**
- Requires Vault infrastructure
- Higher operational complexity
- Additional cost

### Terraform Cloud

#### Setup

1. **In Terraform Cloud Workspace:**
   - Go to Variables tab
   - Add terraform variable: `terraform_cloud_api_key` (sensitive)
   - Add terraform variable: `terraform_cloud_api_secret` (sensitive)

2. **Update .tfvars:**
```hcl
secret_backend = "terraform_cloud"
```

**Pros:**
- Simple setup in Terraform Cloud
- Integrated with Terraform workflow
- Built-in encryption

**Cons:**
- Terraform Cloud/Enterprise only
- Less flexible than dedicated secret managers

## 🔄 Migration Between Backends

### From Environment Variables to AWS Secrets Manager

1. **Create the secret in AWS:**
```bash
aws secretsmanager create-secret \
  --name "confluent-cloud-credentials-prod" \
  --secret-string "{\"api_key\":\"$CONFLUENT_CLOUD_API_KEY\",\"api_secret\":\"$CONFLUENT_CLOUD_API_SECRET\"}"
```

2. **Update .tfvars:**
```diff
- secret_backend = "environment_variables"
+ secret_backend = "aws_secrets_manager"
+ aws_secret_name = "confluent-cloud-credentials-prod"
```

3. **Test the change:**
```bash
terraform plan -var-file="environments/prod.tfvars"
```

## 🛡️ Security Best Practices

### General
- **Use external secret managers for production** (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault)
- **Enable audit logging** on your secret management system
- **Implement least privilege access** with proper IAM/RBAC policies
- **Rotate credentials regularly** (automated where possible)
- **Monitor secret access** and set up alerts for unusual activity

### Environment-Specific Recommendations

| Environment | Recommended Backend | Rationale |
|-------------|-------------------|-----------|
| **Development** | Environment Variables | Simple, fast iteration, low security requirements |
| **UAT/Staging** | AWS Secrets Manager / Azure Key Vault | Production-like security without full complexity |
| **Production** | AWS Secrets Manager / Azure Key Vault / Vault | Maximum security, audit trails, compliance |

### Access Control Examples

#### AWS Secrets Manager Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::ACCOUNT:role/terraform-execution-role"
        ]
      },
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "secretsmanager:ResourceTag/Environment": ["prod", "uat"]
        }
      }
    }
  ]
}
```

#### Azure Key Vault Access Policy
```bash
# Grant access to specific service principal
az keyvault set-policy \
  --name "your-keyvault" \
  --spn "your-service-principal-id" \
  --secret-permissions get \
  --key-permissions get
```

## 🔍 Troubleshooting

### Common Issues

#### AWS Secrets Manager
```bash
Error: operation error Secrets Manager: GetSecretValue, https response error StatusCode: 400
```
**Solution:** Check AWS credentials, region, and secret name

#### Azure Key Vault
```bash
Error: keyvault.BaseClient#GetSecret: Failure responding to request: StatusCode=403
```
**Solution:** Verify access policies and Azure authentication

#### HashiCorp Vault
```bash
Error: Error making API request. Code: 403. Errors: permission denied
```
**Solution:** Check Vault token/authentication and policies

#### Environment Variables
```bash
Error: Invalid provider configuration
```
**Solution:** Verify environment variables are set and exported

### Debug Commands

```bash
# Check which secret backend is configured
terraform output secret_backend_used

# Validate Terraform configuration
terraform validate

# Plan with debug output
TF_LOG=DEBUG terraform plan -var-file="environments/prod.tfvars"

# Test AWS Secrets Manager access
aws secretsmanager get-secret-value --secret-id "your-secret-name"

# Test Azure Key Vault access
az keyvault secret show --vault-name "your-vault" --name "your-secret"

# Test Vault access
vault kv get secret/confluent/prod
```

## 📖 Additional Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Terraform Cloud Variables](https://www.terraform.io/cloud-docs/workspaces/variables)
- [Confluent Cloud API Keys](https://docs.confluent.io/cloud/current/access-management/authenticate/api-keys/api-keys.html) 