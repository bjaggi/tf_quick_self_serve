#!/bin/bash

# Example: Production Environment with Azure Storage Backend
# Use this for production environments on Azure with team collaboration

echo "Setting up production environment with Azure Storage backend..."

# Validate Azure credentials
if ! az account show >/dev/null 2>&1; then
    echo "Error: Azure credentials not configured!"
    echo "Please run: az login"
    exit 1
fi

# Create resource group and storage account (run once per Azure subscription)
read -p "Create resource group and storage account? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    RESOURCE_GROUP="terraform-state-rg"
    STORAGE_ACCOUNT="tfstate$(date +%s)"  # Add timestamp for uniqueness
    LOCATION="East US"
    
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location "$LOCATION"
    
    echo "Creating storage account: $STORAGE_ACCOUNT"
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $RESOURCE_GROUP \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2
    
    echo "Creating storage container..."
    az storage container create \
        --name terraform-state \
        --account-name $STORAGE_ACCOUNT
    
    echo "Storage account created: $STORAGE_ACCOUNT"
fi

# Update backend configuration with your storage account details
echo "Updating backend configuration..."
sed -i.bak "s/your-resource-group/$RESOURCE_GROUP/g" tf_state_externalized/azure-storage.tf
sed -i.bak "s/yourstorageaccount/$STORAGE_ACCOUNT/g" tf_state_externalized/azure-storage.tf

# Initialize backend
./scripts/init-backend.sh azure-storage prod

echo "Backend initialized for production environment"
echo "Next steps:"
echo "1. Configure secrets using Azure Key Vault"
echo "2. Update environments/prod.tfvars with your cluster details"
echo "3. Run: ./scripts/deploy.sh prod plan"
echo "4. Run: ./scripts/deploy.sh prod apply" 