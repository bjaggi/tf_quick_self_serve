#!/bin/bash

# Example: Development Environment with Local Backend
# Use this for individual development, testing, and experimentation

echo "Setting up development environment with local backend..."

# Initialize backend
./scripts/init-backend.sh local dev

# Set up secrets (using environment variables for development)
export CONFLUENT_CLOUD_API_KEY="your-dev-api-key"
export CONFLUENT_CLOUD_API_SECRET="your-dev-api-secret"

echo "Backend initialized for development environment"
echo "Next steps:"
echo "1. Update environments/dev.tfvars with your cluster details"
echo "2. Run: ./scripts/deploy.sh dev plan"
echo "3. Run: ./scripts/deploy.sh dev apply" 