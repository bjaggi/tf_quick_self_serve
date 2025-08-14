#!/bin/bash

# Terraform Backend Initialization Script  
# Usage: ./scripts/init-backend.sh <backend-type> <environment>
# Example: ./scripts/init-backend.sh aws-s3 prod
# Example: ./scripts/init-backend.sh local dev

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if parameters are provided
if [ $# -lt 2 ]; then
    print_error "Backend type and environment are required!"
    echo "Usage: $0 <backend-type> <environment>"
    echo "Backend types: local, aws-s3, gcp-gcs, azure-storage"
    echo "Environments: dev, uat, prod"
    exit 1
fi

BACKEND_TYPE=$1
ENVIRONMENT=$2

# Validate backend type
if [[ ! "$BACKEND_TYPE" =~ ^(local|aws-s3|gcp-gcs|azure-storage)$ ]]; then
    print_error "Invalid backend type: $BACKEND_TYPE"
    echo "Valid backend types: local, aws-s3, gcp-gcs, azure-storage"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, uat, prod"
    exit 1
fi

print_info "Initializing Terraform backend: $BACKEND_TYPE for environment: $ENVIRONMENT"

# Remove existing backend configuration
if [ -f "backend.tf" ]; then
    print_warning "Removing existing backend configuration..."
    rm backend.tf
fi

# Remove existing .terraform directory to force re-initialization
if [ -d ".terraform" ]; then
    print_warning "Removing existing .terraform directory..."
    rm -rf .terraform
fi

# Copy appropriate backend configuration
BACKEND_FILE="tf_state_externalized/${BACKEND_TYPE}.tf"
if [ ! -f "$BACKEND_FILE" ]; then
    print_error "Backend configuration file not found: $BACKEND_FILE"
    exit 1
fi

print_info "Copying backend configuration from $BACKEND_FILE..."
cp "$BACKEND_FILE" backend.tf

# Create states directory structure for local backend
if [ "$BACKEND_TYPE" = "local" ]; then
    mkdir -p states/dev states/uat states/prod
    print_info "Created states directory structure"
fi

# Environment-specific backend customization
case $BACKEND_TYPE in
    local)
        print_info "Customizing local backend for environment: $ENVIRONMENT"
        # Update the state path to include environment
        sed -i.bak "s|states/dev/terraform.tfstate|states/${ENVIRONMENT}/terraform.tfstate|g" backend.tf
        rm backend.tf.bak 2>/dev/null || true
        ;;
    aws-s3)
        print_info "Customizing AWS S3 backend for environment: $ENVIRONMENT"
        # Update the state key to include environment
        sed -i.bak "s|confluent-kafka/dev/terraform.tfstate|confluent-kafka/${ENVIRONMENT}/terraform.tfstate|g" backend.tf
        rm backend.tf.bak 2>/dev/null || true
        
        print_info "Validating AWS credentials..."
        if ! aws sts get-caller-identity >/dev/null 2>&1; then
            print_error "AWS credentials not configured or invalid!"
            echo "Please configure AWS credentials using one of the following methods:"
            echo "  - aws configure"
            echo "  - AWS environment variables"
            echo "  - IAM role (if running on AWS)"
            exit 1
        fi
        print_success "AWS credentials validated"
        ;;
        
    gcp-gcs)
        print_info "Customizing GCP Cloud Storage backend for environment: $ENVIRONMENT"
        # Update the prefix to include environment
        sed -i.bak "s|confluent-kafka/dev|confluent-kafka/${ENVIRONMENT}|g" backend.tf
        rm backend.tf.bak 2>/dev/null || true
        
        print_info "Validating GCP credentials..."
        if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 >/dev/null 2>&1; then
            print_error "GCP credentials not configured or invalid!"
            echo "Please configure GCP credentials using one of the following methods:"
            echo "  - gcloud auth login"
            echo "  - gcloud auth activate-service-account --key-file=path/to/key.json"
            echo "  - Metadata service (if running on GCP)"
            exit 1
        fi
        print_success "GCP credentials validated"
        ;;
        
    azure-storage)
        print_info "Customizing Azure Storage backend for environment: $ENVIRONMENT"
        # Update the key to include environment
        sed -i.bak "s|confluent-kafka/dev/terraform.tfstate|confluent-kafka/${ENVIRONMENT}/terraform.tfstate|g" backend.tf
        rm backend.tf.bak 2>/dev/null || true
        
        print_info "Validating Azure credentials..."
        if ! az account show >/dev/null 2>&1; then
            print_error "Azure credentials not configured or invalid!"
            echo "Please configure Azure credentials using one of the following methods:"
            echo "  - az login"
            echo "  - Azure environment variables (service principal)"
            echo "  - Managed identity (if running on Azure)"
            exit 1
        fi
        print_success "Azure credentials validated"
        ;;
        
    local)
        print_info "Using local backend for environment: $ENVIRONMENT"
        # Update the local path to include environment
        sed -i.bak "s|./terraform.tfstate|./terraform-${ENVIRONMENT}.tfstate|g" backend.tf
        rm backend.tf.bak 2>/dev/null || true
        print_warning "Local backend selected - state will not be shared with team members"
        ;;
esac

# Initialize Terraform with new backend
print_info "Initializing Terraform with $BACKEND_TYPE backend..."
if terraform init; then
    print_success "Terraform backend initialized successfully!"
    print_info "Backend type: $BACKEND_TYPE"
    print_info "Environment: $ENVIRONMENT"
    
    if [ "$BACKEND_TYPE" != "local" ]; then
        print_info "State is now stored remotely and can be shared with team members"
    fi
    
    # Show backend configuration
    print_info "Current backend configuration:"
    terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "terraform_remote_state") | .values' 2>/dev/null || echo "No remote state resources found"
    
else
    print_error "Failed to initialize Terraform backend!"
    exit 1
fi

print_success "Backend initialization completed!"
echo ""
echo "Next steps:"
echo "1. Verify backend configuration: terraform show"
echo "2. Plan your deployment: ./scripts/deploy.sh $ENVIRONMENT plan"
echo "3. Apply your changes: ./scripts/deploy.sh $ENVIRONMENT apply" 