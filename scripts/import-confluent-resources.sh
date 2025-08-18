#!/bin/bash

# Confluent Cloud Resource Import Script
# This script imports existing Confluent Cloud resources into Terraform state
# Usage: ./scripts/import-confluent-resources.sh <environment>
# Example: ./scripts/import-confluent-resources.sh dev

# Allow script to continue even if some imports fail
set +e

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root for consistent path resolution
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to clear provider cache (helpful for permission issues)
clear_provider_cache() {
    print_info "🧹 Clearing Terraform provider cache..."
    if [ -d ".terraform/providers" ]; then
        rm -rf .terraform/providers
        print_success "✅ Provider cache cleared"
        print_info "🔄 Reinitializing Terraform..."
        terraform init -input=false > /dev/null 2>&1
        print_success "✅ Terraform reinitialized with fresh provider cache"
    else
        print_info "No provider cache found to clear"
    fi
}

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Environment is required!"
    echo "Usage: $0 <environment>"
    echo "Environments: dev, uat, prod"
    echo ""
    echo "Options:"
    echo "  --clear-cache    Clear provider cache before importing (useful for permission issues)"
    exit 1
fi

# Parse arguments
CLEAR_CACHE=false
ENVIRONMENT=""

for arg in "$@"; do
    case $arg in
        --clear-cache)
            CLEAR_CACHE=true
            shift
            ;;
        *)
            if [ -z "$ENVIRONMENT" ]; then
                ENVIRONMENT="$arg"
            fi
            shift
            ;;
    esac
done

TFVARS_FILE="$PROJECT_ROOT/environments/${ENVIRONMENT}.tfvars"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, uat, prod"
    exit 1
fi

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    print_error "Environment variables file not found: $TFVARS_FILE"
    exit 1
fi

print_info "🚀 Starting Confluent Cloud Resource Import for environment: $ENVIRONMENT"
print_info "Using tfvars: $TFVARS_FILE"
echo ""

# Check if credentials are set
if [ -z "$CONFLUENT_CLOUD_API_KEY" ] || [ -z "$CONFLUENT_CLOUD_API_SECRET" ]; then
    print_error "Confluent Cloud credentials not set!"
    echo "Please run:"
    echo "export CONFLUENT_CLOUD_API_KEY=\"your-key\""
    echo "export CONFLUENT_CLOUD_API_SECRET=\"your-secret\""
    exit 1
fi

# Clear provider cache if requested (helps with permission issues)
if [ "$CLEAR_CACHE" = true ]; then
    clear_provider_cache
    echo ""
fi

# Extract environment details from tfvars
CLUSTER_ID=$(grep "^cluster_id" "$TFVARS_FILE" | sed 's/.*=\s*"\([^"]*\)".*/\1/' | tr -d ' ')
ENVIRONMENT_ID=$(grep "^environment_id" "$TFVARS_FILE" | sed 's/.*=\s*"\([^"]*\)".*/\1/' | tr -d ' ')
ORGANIZATION_ID=$(grep "^organization_id" "$TFVARS_FILE" | sed 's/.*=\s*"\([^"]*\)".*/\1/' | tr -d ' ')

print_info "📋 Environment Details:"
echo "   Cluster ID: $CLUSTER_ID"
echo "   Environment ID: $ENVIRONMENT_ID"
echo "   Organization ID: $ORGANIZATION_ID"
echo ""

# Get the script directory and ensure we're in project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Ensure Terraform is initialized with modules
print_info "🔧 Ensuring Terraform is initialized..."
if [ ! -d ".terraform" ]; then
    print_info "Initializing Terraform..."
    terraform init >/dev/null 2>&1 || {
        print_error "Failed to initialize Terraform!"
        exit 1
    }
fi

# Configuration paths
CONFIG_DIR="$PROJECT_ROOT/confluent_metadata/${ENVIRONMENT}/json"

# Read expected resources from JSON files
print_info "📖 Reading expected resources from configuration..."

# Topics from JSON
TOPICS_JSON="$CONFIG_DIR/topics.json"
if [ -f "$TOPICS_JSON" ]; then
    TOPIC_NAMES=$(jq -r '.topics[].name' "$TOPICS_JSON" 2>/dev/null || echo "")
    TOPIC_COUNT=$(echo "$TOPIC_NAMES" | wc -w)
    print_info "Found $TOPIC_COUNT topics to import: $(echo $TOPIC_NAMES | tr '\n' ' ')"
else
    print_warning "Topics configuration not found: $TOPICS_JSON"
    TOPIC_NAMES=""
fi

# Service Accounts from JSON
SA_JSON="$CONFIG_DIR/service-accounts.json"
if [ -f "$SA_JSON" ]; then
    SA_NAMES=$(jq -r '.service_accounts[].name' "$SA_JSON" 2>/dev/null || echo "")
    SA_COUNT=$(echo "$SA_NAMES" | wc -w)
    print_info "Found $SA_COUNT service accounts to import: $(echo $SA_NAMES | tr '\n' ' ')"
else
    print_warning "Service accounts configuration not found: $SA_JSON"
    SA_NAMES=""
fi

# RBAC from JSON
RBAC_JSON="$CONFIG_DIR/rbac.json"
if [ -f "$RBAC_JSON" ]; then
    RBAC_COUNT=$(jq '.rbac_bindings_simplified | length' "$RBAC_JSON" 2>/dev/null || echo "0")
    print_info "Found $RBAC_COUNT RBAC bindings to import"
else
    print_warning "RBAC configuration not found: $RBAC_JSON"
    RBAC_COUNT=0
fi

echo ""

# Function to import a resource with error handling
import_resource() {
    local resource_address="$1"
    local resource_id="$2"
    local description="$3"
    
    print_info "Importing $description..."
    echo "   Resource: $resource_address"
    echo "   ID: $resource_id"
    
    # Capture the output and handle errors gracefully
    local import_output
    if import_output=$(terraform import -var-file="$TFVARS_FILE" "$resource_address" "$resource_id" 2>&1); then
        if echo "$import_output" | grep -q "Import successful"; then
            print_success "✅ Successfully imported $description"
            return 0
        elif echo "$import_output" | grep -q "already managed"; then
            print_success "✅ $description already imported"
            return 0
        else
            print_warning "⚠️  Unexpected response for $description"
            echo "$import_output" | head -3
            return 1
        fi
    else
        if echo "$import_output" | grep -q "already managed\|already exists in state"; then
            print_success "✅ $description already imported"
            return 0
        elif echo "$import_output" | grep -q "403 Forbidden\|403.*Forbidden"; then
            print_error "❌ Permission denied for $description"
            print_warning "This is likely due to insufficient API key permissions or provider cache issues."
            echo ""
            echo "💡 Troubleshooting steps:"
            echo "   1. Verify your API key has OrganizationAdmin or EnvironmentAdmin permissions:"
            echo "      - Go to Confluent Cloud Console → Administration → Access → API Keys"
            echo "      - Find key: $CONFLUENT_CLOUD_API_KEY"
            echo "      - Check service account roles"
            echo ""
            echo "   2. If permissions were recently updated, clear provider cache:"
            echo "      rm -rf .terraform/providers && terraform init"
            echo ""
            echo "   3. Or re-run this script with cache clearing:"
            echo "      $0 $ENVIRONMENT --clear-cache"
            echo ""
            return 1
        else
            print_warning "⚠️  Failed to import $description"
            echo "$import_output" | head -2
            return 1
        fi
    fi
}

# Import Topics
print_info "🏷️  Importing Kafka Topics..."
IMPORTED_TOPICS=0
for topic in $TOPIC_NAMES; do
    if [ -n "$topic" ]; then
        if import_resource "module.topics.confluent_kafka_topic.topics[\"$topic\"]" "$CLUSTER_ID/$topic" "topic '$topic'"; then
            ((IMPORTED_TOPICS++))
        fi
    fi
done

echo ""

# Import Service Accounts  
print_info "👤 Importing Service Accounts..."
print_info "Finding service account IDs using Terraform data source..."

# Create a temporary Terraform file to query individual service accounts
# Build the file dynamically based on actual service account names
cat > temp_query_sa.tf << EOF
terraform {
  required_providers {
    confluent = {
      source = "confluentinc/confluent"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_api_key_env_var
  cloud_api_secret = var.confluent_api_secret_env_var
}

variable "confluent_api_key_env_var" {
  type = string
}

variable "confluent_api_secret_env_var" {
  type = string
}

# Query individual service accounts by display name (dynamically generated)
EOF

# Add data sources for each service account dynamically
SA_INDEX=0
for sa_name in $SA_NAMES; do
    if [ -n "$sa_name" ]; then
        # Create a safe identifier for Terraform (replace hyphens with underscores)
        SA_IDENTIFIER=$(echo "$sa_name" | sed 's/-/_/g')
        cat >> temp_query_sa.tf << EOF
data "confluent_service_account" "$SA_IDENTIFIER" {
  display_name = "$sa_name"
}

EOF
        SA_INDEX=$((SA_INDEX + 1))
    fi
done

# Add the output section dynamically
cat >> temp_query_sa.tf << 'EOF'
# Output the service account IDs
output "service_account_ids" {
  value = {
EOF

# Add output entries for each service account
for sa_name in $SA_NAMES; do
    if [ -n "$sa_name" ]; then
        SA_IDENTIFIER=$(echo "$sa_name" | sed 's/-/_/g')
        cat >> temp_query_sa.tf << EOF
    "$sa_name" = data.confluent_service_account.$SA_IDENTIFIER.id
EOF
    fi
done

cat >> temp_query_sa.tf << 'EOF'
  }
}
EOF

# Initialize and query service accounts
export TF_VAR_confluent_api_key_env_var="$CONFLUENT_CLOUD_API_KEY"
export TF_VAR_confluent_api_secret_env_var="$CONFLUENT_CLOUD_API_SECRET"

# Create a completely isolated temporary directory for the query
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
cp "$PROJECT_ROOT/temp_query_sa.tf" .

print_info "Querying Confluent Cloud for service account IDs..."
if terraform init >/dev/null 2>&1; then
    if terraform apply -auto-approve >/dev/null 2>&1; then
        SA_IDS_JSON=$(terraform output -json service_account_ids 2>/dev/null || echo "{}")
        print_info "Successfully found service account IDs!"
        
        # Go back to original directory and completely clean up temp files first
        cd "$PROJECT_ROOT"
        rm -f temp_query_sa.tf
        rm -rf "$TEMP_DIR" 2>/dev/null || true
        
        # Now import with the IDs we found - dynamically for each service account
        IMPORTED_SA=0
        for sa_name in $SA_NAMES; do
            if [ -n "$sa_name" ]; then
                SA_ID=$(echo "$SA_IDS_JSON" | jq -r ".[\"$sa_name\"] // empty" 2>/dev/null || echo "")
                if [ -n "$SA_ID" ] && [ "$SA_ID" != "null" ] && [ "$SA_ID" != "" ]; then
                    if import_resource "module.service_accounts.confluent_service_account.service_accounts[\"$sa_name\"]" "$SA_ID" "service account '$sa_name'"; then
                        ((IMPORTED_SA++))
                    fi
                else
                    print_warning "Could not find ID for service account: $sa_name"
                fi
            fi
        done
    else
        cd "$PROJECT_ROOT"
        rm -f temp_query_sa.tf
        rm -rf "$TEMP_DIR" 2>/dev/null || true
        print_warning "Failed to query service accounts. Service accounts may need manual import."
        IMPORTED_SA=0
    fi
else
    cd "$PROJECT_ROOT"
    rm -f temp_query_sa.tf
    rm -rf "$TEMP_DIR" 2>/dev/null || true
    print_warning "Failed to initialize Terraform for service account query."
    IMPORTED_SA=0
fi

echo ""

# Import RBAC Bindings (these are complex and might need manual handling)
print_info "🔐 RBAC Bindings Import..."
print_warning "RBAC bindings have complex IDs and may need manual import."
print_info "After service accounts are imported, you can run:"
echo "   terraform plan -var-file=\"$TFVARS_FILE\""
echo "   This will show you the exact RBAC binding IDs needed for import."

echo ""

# Summary
print_info "📊 Import Summary:"
echo "   Topics imported: $IMPORTED_TOPICS / $(echo $TOPIC_NAMES | wc -w)"
echo "   Service Accounts imported: $IMPORTED_SA / $(echo $SA_NAMES | wc -w)"
echo "   RBAC Bindings: Needs manual review"

echo ""

# Final verification
print_info "🔍 Running Terraform Plan to verify imports..."
if terraform plan -var-file="$TFVARS_FILE" -out="/dev/null" >/dev/null 2>&1; then
    print_success "✅ Terraform plan successful - all imported resources are in sync!"
else
    print_warning "⚠️  Some resources may still need to be imported or configured."
    echo "   Run: terraform plan -var-file=\"$TFVARS_FILE\" to see remaining issues"
fi

print_success "🎉 Import process completed!"
echo ""
echo "Next steps:"
echo "1. Run: terraform plan -var-file=\"$TFVARS_FILE\" to verify all resources"
echo "2. If there are still resources to import, the plan will show you the exact commands"
echo "3. Once everything is imported, run: terraform apply to ensure state is current"