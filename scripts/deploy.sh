#!/bin/bash

# Confluent Kafka Infrastructure Deployment Script
# Usage: ./scripts/deploy.sh <environment> [action]
# Example: ./scripts/deploy.sh dev plan
# Example: ./scripts/deploy.sh prod apply

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

# Setup logging
setup_logging() {
    local environment=$1
    local action=$2
    
    # Create logs directory structure
    LOG_BASE_DIR="logs"
    LOG_ENV_DIR="$LOG_BASE_DIR/$environment"
    mkdir -p "$LOG_ENV_DIR"
    
    # Generate timestamp for log files
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    
    # Set log file paths
    LOG_FILE="$LOG_ENV_DIR/${action}_${TIMESTAMP}.log"
    FULL_LOG_FILE="$LOG_ENV_DIR/${action}_${TIMESTAMP}_full.log"
    
    print_info "Logging to: $LOG_FILE"
    print_info "Full output log: $FULL_LOG_FILE"
    
    # Log session start
    echo "=== Terraform $action started at $(date) ===" >> "$FULL_LOG_FILE"
    echo "Environment: $environment" >> "$FULL_LOG_FILE"
    echo "Action: $action" >> "$FULL_LOG_FILE"
    echo "Working Directory: $(pwd)" >> "$FULL_LOG_FILE"
    echo "User: $(whoami)" >> "$FULL_LOG_FILE"
    echo "================================================" >> "$FULL_LOG_FILE"
    echo "" >> "$FULL_LOG_FILE"
}

# Execute terraform command with logging
tf_execute() {
    local cmd="$1"
    local description="$2"
    
    echo "=== $description - $(date) ===" >> "$FULL_LOG_FILE"
    echo "Command: $cmd" >> "$FULL_LOG_FILE"
    echo "---" >> "$FULL_LOG_FILE"
    
    # Execute command with both display and logging
    eval "$cmd" 2>&1 | tee -a "$LOG_FILE" "$FULL_LOG_FILE"
    local exit_code=${PIPESTATUS[0]}
    
    echo "" >> "$FULL_LOG_FILE"
    echo "Exit code: $exit_code" >> "$FULL_LOG_FILE"
    echo "=== End $description - $(date) ===" >> "$FULL_LOG_FILE"
    echo "" >> "$FULL_LOG_FILE"
    
    return $exit_code
}

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory for all operations
cd "$PROJECT_ROOT"

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Environment is required!"
    echo "Usage: $0 <environment> [action]"
    echo "Environments: dev, uat, prod"
    echo "Actions: plan, apply, destroy (default: plan)"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-plan}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, uat, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|show|state)$ ]]; then
    print_error "Invalid action: $ACTION"
    echo "Valid actions: plan, apply, destroy, show, state"
    exit 1
fi

# Check if required files exist
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"
CONFIG_DIR="confluent_metadata/${ENVIRONMENT}/json"

if [ ! -f "$TFVARS_FILE" ]; then
    print_error "Environment variables file not found: $TFVARS_FILE"
    exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
    print_error "Configuration directory not found: $CONFIG_DIR"
    exit 1
fi

# Check if using environment variables for secrets and if they are set
SECRET_BACKEND=$(grep "^secret_backend" "$TFVARS_FILE" | sed 's/.*=\s*"\([^"]*\)".*/\1/' | tr -d ' ')

if [ "$SECRET_BACKEND" = "environment_variables" ] || [ -z "$SECRET_BACKEND" ]; then
    if [ -z "$CONFLUENT_CLOUD_API_KEY" ] || [ -z "$CONFLUENT_CLOUD_API_SECRET" ]; then
        print_error "Confluent Cloud credentials not set!"
        echo "Using environment_variables secret backend, but credentials are missing."
        echo "Please set the following environment variables:"
        echo "  export CONFLUENT_CLOUD_API_KEY=\"your-api-key\""
        echo "  export CONFLUENT_CLOUD_API_SECRET=\"your-api-secret\""
        echo ""
        echo "Or configure a different secret backend in $TFVARS_FILE:"
        echo "  - aws_secrets_manager"
        echo "  - azure_keyvault"
        echo "  - hashicorp_vault"
        echo "  - terraform_cloud"
        exit 1
    fi
    # Pass environment variables to Terraform
    export TF_VAR_confluent_api_key_env_var="$CONFLUENT_CLOUD_API_KEY"
    export TF_VAR_confluent_api_secret_env_var="$CONFLUENT_CLOUD_API_SECRET"
else
    print_info "Using secret backend: $SECRET_BACKEND"
    print_info "Make sure your secret backend is properly configured"
fi

print_info "Deploying to environment: $ENVIRONMENT"
print_info "Action: $ACTION"
print_info "Using tfvars: $TFVARS_FILE"
print_info "Using config: $CONFIG_DIR"

# Auto-initialize backend for environment
if [ ! -f "backend.tf" ]; then
    print_warning "No backend configuration found. Auto-initializing local backend for $ENVIRONMENT..."
    "$PROJECT_ROOT/scripts/init-backend.sh" local $ENVIRONMENT
else
    # Check if backend is configured for the correct environment
    CURRENT_ENV_IN_BACKEND=$(grep -o "states/[^/]*/terraform.tfstate" backend.tf | sed 's|states/||' | sed 's|/terraform.tfstate||' || echo "unknown")
    if [ "$CURRENT_ENV_IN_BACKEND" != "$ENVIRONMENT" ]; then
        print_warning "Backend configured for '$CURRENT_ENV_IN_BACKEND' but deploying to '$ENVIRONMENT'"
        print_warning "Re-initializing backend for correct environment..."
        
        # Determine current backend type
        CURRENT_BACKEND_TYPE="local"
        if grep -q 'backend "s3"' backend.tf; then
            CURRENT_BACKEND_TYPE="aws-s3"
        elif grep -q 'backend "gcs"' backend.tf; then
            CURRENT_BACKEND_TYPE="gcp-gcs"
        elif grep -q 'backend "azurerm"' backend.tf; then
            CURRENT_BACKEND_TYPE="azure-storage"
        fi
        
        "$PROJECT_ROOT/scripts/init-backend.sh" $CURRENT_BACKEND_TYPE $ENVIRONMENT
    fi
fi

# Show current backend configuration
BACKEND_TYPE=$(grep -E "backend \"(local|s3|gcs|azurerm)\"" backend.tf | sed -E 's/.*backend "([^"]+)".*/\1/' | head -1)
print_info "Using backend: $BACKEND_TYPE"

# Setup logging for this session
setup_logging "$ENVIRONMENT" "$ACTION"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    print_info "Initializing Terraform..."
    tf_execute "terraform init" "Terraform Init"
fi

# Execute the requested action
case $ACTION in
    plan)
        print_info "Running Terraform plan..."
        tf_execute "terraform plan -var-file=\"$TFVARS_FILE\" -out=\"${ENVIRONMENT}.tfplan\"" "Terraform Plan"
        print_success "Plan completed! Review the changes above."
        print_info "To apply these changes, run: ./scripts/deploy.sh $ENVIRONMENT apply"
        ;;
    apply)
        # Check if plan file exists
        if [ -f "${ENVIRONMENT}.tfplan" ]; then
            print_info "Applying from existing plan file..."
            tf_execute "terraform apply \"${ENVIRONMENT}.tfplan\"" "Terraform Apply (from plan)"
            rm "${ENVIRONMENT}.tfplan"
        else
            print_warning "No plan file found. Running plan and apply..."
            tf_execute "terraform apply -var-file=\"$TFVARS_FILE\"" "Terraform Apply (direct)"
        fi
        print_success "Deployment to $ENVIRONMENT completed successfully!"
        ;;
    destroy)
        print_warning "This will DESTROY all resources in $ENVIRONMENT environment!"
        read -p "Are you sure? Type 'yes' to continue: " -r
        if [[ $REPLY == "yes" ]]; then
            tf_execute "terraform destroy -var-file=\"$TFVARS_FILE\"" "Terraform Destroy"
            print_success "Resources in $ENVIRONMENT destroyed."
        else
            print_info "Destroy cancelled."
        fi
        ;;
    show)
        print_info "Showing current state..."
        tf_execute "terraform show" "Terraform Show"
        ;;
    state)
        print_info "Listing current state resources..."
        tf_execute "terraform state list" "Terraform State List"
        ;;
esac

# Log session completion
echo "=== Terraform $ACTION session completed at $(date) ===" >> "$FULL_LOG_FILE"
echo "Script completed successfully" >> "$FULL_LOG_FILE"
echo "" >> "$FULL_LOG_FILE"

print_success "Script completed!"
print_info "Logs saved to: $LOG_FILE and $FULL_LOG_FILE" 