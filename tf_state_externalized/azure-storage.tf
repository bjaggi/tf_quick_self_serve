# Azure Storage Backend Configuration
# Use this for production environments on Azure with team collaboration  
# State files will be stored in Azure Storage Account with automatic state locking

terraform {
  backend "azurerm" {
    resource_group_name  = "your-resource-group"           # Resource group containing storage account
    storage_account_name = "yourstorageaccount"            # Storage account name (must be globally unique)
    container_name       = "terraform-state"              # Container name for state files
    key                  = "confluent-kafka/dev/terraform.tfstate"  # State file name
    
    # Optional: Use different authentication methods
    # use_msi              = true                          # Use Managed Service Identity
    # use_azuread_auth     = true                         # Use Azure AD authentication
    
    # Optional: Specify subscription and tenant
    # subscription_id      = "your-subscription-id"
    # tenant_id           = "your-tenant-id"
  }
}

# Prerequisites:
# 1. Azure Storage Account with container for state storage
# 2. Service Principal or Managed Identity with appropriate permissions
# 3. Azure credentials configured (Azure CLI, service principal, or managed identity)

# Benefits:
# - Team collaboration with shared state
# - Built-in state locking (no additional resources needed)
# - Versioning through Azure Storage
# - Encryption at rest and in transit
# - Integration with Azure RBAC
# - Geo-redundant storage options

# Setup Commands:
# az group create --name "your-resource-group" --location "East US"
# az storage account create \
#   --name "yourstorageaccount" \
#   --resource-group "your-resource-group" \
#   --location "East US" \
#   --sku "Standard_LRS" \
#   --kind "StorageV2"
# az storage container create \
#   --name "terraform-state" \
#   --account-name "yourstorageaccount"

# Required Azure permissions for service principal:
# - Storage Blob Data Contributor (on the storage account or container)
# - Reader (on the resource group)

# Example service principal creation:
# az ad sp create-for-rbac \
#   --name "terraform-state-management" \
#   --role "Storage Blob Data Contributor" \
#   --scopes "/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/STORAGE_ACCOUNT" 