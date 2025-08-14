#!/bin/bash

# Quick Development Setup Script
# This script sets up the development environment with minimal dependencies

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Confluent Kafka Infrastructure for Development${NC}"

# Check if environment variables are set
if [ -z "$CONFLUENT_CLOUD_API_KEY" ] || [ -z "$CONFLUENT_CLOUD_API_SECRET" ]; then
    echo "❌ Confluent Cloud credentials not set!"
    echo "Please set the following environment variables:"
    echo "  export CONFLUENT_CLOUD_API_KEY=\"your-api-key\""
    echo "  export CONFLUENT_CLOUD_API_SECRET=\"your-api-secret\""
    exit 1
fi

echo -e "${GREEN}✅ Confluent Cloud credentials found${NC}"

# Check if dev.tfvars has been updated
if grep -q "lkc-xxxxxx" environments/dev.tfvars; then
    echo "⚠️  Please update environments/dev.tfvars with your actual cluster details:"
    echo "   - cluster_id: Replace 'lkc-xxxxxx' with your actual cluster ID"
    echo "   - environment_id: Replace 'env-xxxxxx' with your actual environment ID"
    echo "   - schema_registry_id: Replace 'lsrc-xxxxxx' with your actual schema registry ID"
    echo ""
    read -p "Press Enter after updating environments/dev.tfvars..."
fi

# Initialize local backend
echo -e "${BLUE}🏗️  Initializing local backend...${NC}"
./scripts/init-backend.sh local dev

# Set environment variables for Terraform
export TF_VAR_confluent_api_key_env_var="$CONFLUENT_CLOUD_API_KEY"
export TF_VAR_confluent_api_secret_env_var="$CONFLUENT_CLOUD_API_SECRET"

# Plan deployment
echo -e "${BLUE}📋 Planning deployment...${NC}"
./scripts/deploy.sh dev plan

echo -e "${GREEN}✅ Development environment ready!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the plan above"
echo "2. Run: ./scripts/deploy.sh dev apply"
echo "3. Or run: terraform apply -var-file=\"environments/dev.tfvars\"" 