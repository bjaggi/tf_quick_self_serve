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

# Execute terraform command with logging and enhanced error handling
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

# Check if a plan file is stale
is_plan_stale() {
    local plan_file="$1"
    
    if [ ! -f "$plan_file" ]; then
        return 1  # Plan file doesn't exist (treat as stale)
    fi
    
    # Try to show the plan file - if this fails, it's definitely stale/corrupted
    if ! terraform show "$plan_file" >/dev/null 2>&1; then
        return 1  # Plan file is corrupted or stale
    fi
    
    # The plan file is readable, so it's likely valid
    # Note: We can't easily detect staleness without trying to apply,
    # so we'll let terraform apply handle the stale detection
    return 0  # Plan file appears valid (terraform apply will catch staleness)
}

# Clean up plan files
cleanup_plan_files() {
    print_info "🧹 Cleaning up old plan files..."
    rm -f *.tfplan
    print_success "✅ Plan files cleaned up"
}

# Handle RBAC operations with timeout and retry
apply_with_rbac_handling() {
    local tfvars_file="$1"
    local max_retries=2
    local timeout_seconds=300  # 5 minutes timeout
    
    for attempt in $(seq 1 $max_retries); do
        print_info "🚀 Starting apply operation (attempt $attempt/$max_retries)..."
        
        if [ $attempt -gt 1 ]; then
            print_warning "⏳ RBAC operations can take 2-3 minutes. Please be patient..."
            print_info "💡 If this continues to timeout, you may need to:"
            echo "   1. Check Confluent Cloud status"
            echo "   2. Retry with: ./scripts/deploy.sh $ENVIRONMENT apply"
            echo "   3. Run terraform state list to see what was created"
        fi
        
        # Use timeout command if available
        local timeout_cmd=""
        if command -v timeout >/dev/null 2>&1; then
            timeout_cmd="timeout ${timeout_seconds}s"
            print_info "⏰ Setting ${timeout_seconds}s timeout for terraform apply"
        fi
        
        # Execute terraform apply with timeout
        if $timeout_cmd terraform apply -var-file="$tfvars_file" -auto-approve 2>&1 | tee -a "$LOG_FILE" "$FULL_LOG_FILE"; then
            print_success "✅ Apply operation completed successfully!"
            return 0
        else
            local exit_code=$?
            
            if [ $exit_code -eq 124 ]; then  # timeout exit code
                print_warning "⏰ Apply operation timed out after ${timeout_seconds} seconds"
                print_info "🔍 Checking what resources were created..."
                terraform state list 2>/dev/null | grep -E "rbac|role_binding" && print_info "Some RBAC bindings may have been created"
            elif [ $exit_code -eq 130 ]; then  # Ctrl+C interrupt
                print_warning "⚠️  Apply operation was interrupted"
                print_info "🔍 Checking current state..."
                terraform state list 2>/dev/null | grep -E "rbac|role_binding" && print_info "Some RBAC bindings may have been partially created"
            else
                print_warning "⚠️  Apply operation failed with exit code: $exit_code"
            fi
            
            if [ $attempt -lt $max_retries ]; then
                print_info "🔄 Will retry in 10 seconds..."
                sleep 10
            else
                print_error "❌ All apply attempts failed"
                print_info "💡 To recover:"
                echo "   1. Check current state: terraform state list"
                echo "   2. Clean up if needed: terraform state rm <resource>"
                echo "   3. Retry: ./scripts/deploy.sh $ENVIRONMENT apply"
                return $exit_code
            fi
        fi
    done
}

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory for all operations
cd "$PROJECT_ROOT"

# Signal trap for cleanup on interrupt
cleanup_on_interrupt() {
    print_warning "⚠️  Operation interrupted! Cleaning up..."
    cleanup_plan_files
    print_info "💡 You may need to check terraform state and retry the operation"
    exit 130
}
trap cleanup_on_interrupt INT TERM

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Environment is required!"
    echo "Usage: $0 <environment> [action]"
    echo "Environments: dev, uat, prod"
    echo "Actions: plan, apply, destroy, show, state, cleanup (default: plan)"
    echo ""
    echo "Special actions:"
    echo "  cleanup    Remove stale plan files and reset state"
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
        # Check if plan file exists and if it's stale
        if [ -f "${ENVIRONMENT}.tfplan" ]; then
            print_info "Found existing plan file: ${ENVIRONMENT}.tfplan"
            
            # Try to apply from plan file, with fallback to fresh apply if stale
            print_info "📋 Attempting to apply from plan file..."
            
            # Capture the apply output to detect staleness
            apply_output=""
            if apply_output=$(terraform apply "${ENVIRONMENT}.tfplan" 2>&1); then
                rm "${ENVIRONMENT}.tfplan"
                print_success "✅ Applied successfully from plan file!"
                echo "$apply_output"
            else
                # Check if the error is due to stale plan
                if echo "$apply_output" | grep -q "Saved plan is stale"; then
                    print_warning "⚠️  Plan file is stale, removing and running fresh apply..."
                    rm "${ENVIRONMENT}.tfplan"
                    apply_with_rbac_handling "$TFVARS_FILE"
                else
                    # Other error, show it and exit
                    print_error "❌ Apply from plan file failed:"
                    echo "$apply_output"
                    cleanup_plan_files
                    exit 1
                fi
            fi
        else
            print_info "No plan file found. Running direct apply with RBAC handling..."
            apply_with_rbac_handling "$TFVARS_FILE"
        fi
        
        # Final success message (only if we get here)
        print_success "🎉 Deployment to $ENVIRONMENT completed successfully!"
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
    cleanup)
        print_info "🧹 Cleaning up stale plan files and resetting state..."
        cleanup_plan_files
        
        # Also clear any .terraform lock files that might be causing issues
        if [ -f ".terraform.lock.hcl" ]; then
            print_info "🔓 Clearing terraform lock file..."
            rm -f ".terraform.lock.hcl"
        fi
        
        # Clear provider cache if it exists
        if [ -d ".terraform/providers" ]; then
            print_info "🗑️  Clearing provider cache..."
            rm -rf .terraform/providers
            print_info "🔄 Reinitializing terraform..."
            terraform init -input=false > /dev/null 2>&1 || true
        fi
        
        print_success "✅ Cleanup completed!"
        print_info "💡 Next steps:"
        echo "   1. Run: ./scripts/deploy.sh $ENVIRONMENT plan"
        echo "   2. Review changes and apply: ./scripts/deploy.sh $ENVIRONMENT apply"
        ;;
    *)
        print_error "Unknown action: $ACTION"
        echo "Valid actions: plan, apply, destroy, show, state, cleanup"
        exit 1
        ;;
esac

# Log session completion
echo "=== Terraform $ACTION session completed at $(date) ===" >> "$FULL_LOG_FILE"
echo "Script completed successfully" >> "$FULL_LOG_FILE"
echo "" >> "$FULL_LOG_FILE"

print_success "Script completed!"
print_info "Logs saved to: $LOG_FILE and $FULL_LOG_FILE" 