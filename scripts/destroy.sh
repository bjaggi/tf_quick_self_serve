#!/bin/bash

# Confluent Kafka Infrastructure Destroy Script
# Usage: ./scripts/destroy.sh <environment> [options]
# Example: ./scripts/destroy.sh dev
# Example: ./scripts/destroy.sh prod --target=module.topics

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

# Function to show usage
show_usage() {
    echo "Usage: $0 <environment> [options]"
    echo
    echo "Environments: dev, uat, prod"
    echo
    echo "Options:"
    echo "  --plan              Show destroy plan without executing"
    echo "  --target=<resource> Destroy specific resource(s)"
    echo "  --backup-state      Backup state file before destroy"
    echo "  --force             Skip confirmation prompts"
    echo "  --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 dev --plan                              # Show what would be destroyed"
    echo "  $0 dev --target=module.topics              # Destroy only topics"
    echo "  $0 uat --backup-state                      # Backup state before destroy"
    echo "  $0 prod --force                            # Skip confirmations (dangerous!)"
}

# Parse command line arguments
ENVIRONMENT=""
PLAN_ONLY=false
TARGET=""
BACKUP_STATE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --plan)
            PLAN_ONLY=true
            shift
            ;;
        --target=*)
            TARGET="${1#*=}"
            shift
            ;;
        --backup-state)
            BACKUP_STATE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$ENVIRONMENT" ]; then
                ENVIRONMENT="$1"
            else
                print_error "Multiple environments specified: $ENVIRONMENT and $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if environment is provided
if [ -z "$ENVIRONMENT" ]; then
    print_error "Environment is required!"
    show_usage
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, uat, prod"
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
        exit 1
    fi
    # Pass environment variables to Terraform
    export TF_VAR_confluent_api_key_env_var="$CONFLUENT_CLOUD_API_KEY"
    export TF_VAR_confluent_api_secret_env_var="$CONFLUENT_CLOUD_API_SECRET"
else
    print_info "Using secret backend: $SECRET_BACKEND"
    print_info "Make sure your secret backend is properly configured"
fi

print_info "Environment: $ENVIRONMENT"
print_info "Using tfvars: $TFVARS_FILE"
print_info "Using config: $CONFIG_DIR"

# Auto-initialize backend for environment
if [ ! -f "backend.tf" ]; then
    print_warning "No backend configuration found. Auto-initializing local backend for $ENVIRONMENT..."
    ./scripts/init-backend.sh local $ENVIRONMENT
else
    # Check if backend is configured for the correct environment
    CURRENT_ENV_IN_BACKEND=$(grep -o "states/[^/]*/terraform.tfstate" backend.tf | sed 's|states/||' | sed 's|/terraform.tfstate||' || echo "unknown")
    if [ "$CURRENT_ENV_IN_BACKEND" != "$ENVIRONMENT" ]; then
        print_warning "Backend configured for '$CURRENT_ENV_IN_BACKEND' but targeting '$ENVIRONMENT'"
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
        
        ./scripts/init-backend.sh $CURRENT_BACKEND_TYPE $ENVIRONMENT
    fi
fi

# Show current backend configuration
BACKEND_TYPE=$(grep -E "backend \"(local|s3|gcs|azurerm)\"" backend.tf | sed -E 's/.*backend "([^"]+)".*/\1/' | head -1)
print_info "Using backend: $BACKEND_TYPE"

# Setup logging for this session
setup_logging "$ENVIRONMENT" "destroy"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    print_info "Initializing Terraform..."
    tf_execute "terraform init" "Terraform Init"
fi

# Backup state file if requested
if [ "$BACKUP_STATE" = true ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="states/${ENVIRONMENT}/backups"
    
    mkdir -p "$BACKUP_DIR"
    
    if [ "$BACKEND_TYPE" = "local" ]; then
        STATE_FILE="terraform.tfstate"
        if [ -f "$STATE_FILE" ]; then
            cp "$STATE_FILE" "${BACKUP_DIR}/terraform_${TIMESTAMP}.tfstate"
            print_success "State backed up to: ${BACKUP_DIR}/terraform_${TIMESTAMP}.tfstate"
        fi
    else
        # For remote backends, pull the state
            tf_execute "terraform state pull > \"${BACKUP_DIR}/terraform_${TIMESTAMP}.tfstate\"" "Terraform State Backup"
    print_success "State backed up to: ${BACKUP_DIR}/terraform_${TIMESTAMP}.tfstate"
    fi
fi

# Build terraform command
TERRAFORM_CMD="terraform"
if [ "$PLAN_ONLY" = true ]; then
    TERRAFORM_CMD="$TERRAFORM_CMD plan -destroy"
else
    TERRAFORM_CMD="$TERRAFORM_CMD destroy"
fi

TERRAFORM_CMD="$TERRAFORM_CMD -var-file=\"$TFVARS_FILE\""

if [ -n "$TARGET" ]; then
    TERRAFORM_CMD="$TERRAFORM_CMD -target=\"$TARGET\""
    print_info "Targeting specific resource: $TARGET"
fi

if [ "$FORCE" = true ] && [ "$PLAN_ONLY" = false ]; then
    TERRAFORM_CMD="$TERRAFORM_CMD -auto-approve"
fi

# Show what will be destroyed
if [ "$PLAN_ONLY" = true ]; then
    print_info "Showing destroy plan for $ENVIRONMENT environment..."
    tf_execute "$TERRAFORM_CMD" "Terraform Destroy Command"
    print_success "Destroy plan completed!"
    exit 0
fi

# Safety warnings and confirmations
print_warning "═══════════════════════════════════════════════════════════════"
print_warning "  DANGER: This will DESTROY resources in $ENVIRONMENT environment!"
print_warning "═══════════════════════════════════════════════════════════════"

if [ -n "$TARGET" ]; then
    print_warning "Target resource: $TARGET"
else
    print_warning "ALL RESOURCES will be destroyed!"
fi

echo
print_info "Current resources in state:"
    tf_execute "terraform state list | head -10" "Terraform State List Preview"
    RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l)
if [ "$RESOURCE_COUNT" -gt 10 ]; then
    print_info "... and $((RESOURCE_COUNT - 10)) more resources"
fi
echo

# Production extra safety check
if [ "$ENVIRONMENT" = "prod" ] && [ "$FORCE" = false ]; then
    print_error "PRODUCTION ENVIRONMENT DETECTED!"
    print_warning "Extra confirmation required for production destroy."
    echo
    read -p "Type the environment name to confirm (prod): " -r ENV_CONFIRM
    if [ "$ENV_CONFIRM" != "prod" ]; then
        print_info "Destroy cancelled - environment name mismatch."
        exit 1
    fi
fi

# Final confirmation
if [ "$FORCE" = false ]; then
    echo
    read -p "Type 'DELETE' in all caps to confirm destroy: " -r DELETE_CONFIRM
    if [ "$DELETE_CONFIRM" != "DELETE" ]; then
        print_info "Destroy cancelled."
        exit 1
    fi
fi

# Execute destroy
print_info "Executing destroy command..."
print_info "Command: $TERRAFORM_CMD"
echo

tf_execute "$TERRAFORM_CMD" "Terraform Destroy Command"

# Post-destroy cleanup
if [ $? -eq 0 ]; then
    print_success "Resources in $ENVIRONMENT environment destroyed successfully!"
    
    # Clean up plan files
    if [ -f "${ENVIRONMENT}.tfplan" ]; then
        rm "${ENVIRONMENT}.tfplan"
        print_info "Cleaned up plan file: ${ENVIRONMENT}.tfplan"
    fi
    
    # Clean up destroy plan files
    if [ -f "${ENVIRONMENT}-destroy.tfplan" ]; then
        rm "${ENVIRONMENT}-destroy.tfplan"
        print_info "Cleaned up destroy plan file: ${ENVIRONMENT}-destroy.tfplan"
    fi
    
    print_info "Destroy operation completed!"
else
    print_error "Destroy operation failed!"
    exit 1
fi

# Log session completion
echo "=== Terraform destroy session completed at $(date) ===" >> "$FULL_LOG_FILE"
echo "Script completed successfully" >> "$FULL_LOG_FILE"
echo "" >> "$FULL_LOG_FILE"

print_success "Script completed!"
print_info "Logs saved to: $LOG_FILE and $FULL_LOG_FILE"