#!/bin/bash

# Example usage script for data-driven configuration
# This script demonstrates how to use the new data-driven configuration approach

set -e

echo "🚀 Confluent Kafka Data-Driven Configuration Example"
echo "=================================================="

# Check if example file exists
if [ ! -f "examples/data-driven.tfvars" ]; then
    echo "❌ Error: examples/data-driven.tfvars not found"
    echo "   Please run this script from the project root directory"
    exit 1
fi

echo "📋 Example configuration will create:"
echo "   - 2 Kafka topics (topic-a, topic-b)"
echo "   - 7 service accounts"
echo "   - Automated RBAC role bindings based on producer/consumer configuration"
echo

# Validate the configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Show what would be created
echo "📝 Planning deployment with data-driven configuration..."
echo "   Using: examples/data-driven.tfvars"
echo

# Check if required variables are set
if [ -z "$CONFLUENT_CLOUD_API_KEY" ] || [ -z "$CONFLUENT_CLOUD_API_SECRET" ]; then
    echo "⚠️  Warning: Confluent Cloud API credentials not set in environment"
    echo "   Set CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET"
    echo "   Or configure alternative secret management backend"
    echo
fi

if [ -z "$KAFKA_API_KEY" ] || [ -z "$KAFKA_API_SECRET" ]; then
    echo "⚠️  Warning: Kafka API credentials not set in environment"
    echo "   Set KAFKA_API_KEY and KAFKA_API_SECRET"
    echo
fi

# Run terraform plan
terraform plan -var-file="examples/data-driven.tfvars"

echo
echo "✅ Plan completed successfully!"
echo
echo "📚 Next steps:"
echo "   1. Review the plan output above"
echo "   2. Update examples/data-driven.tfvars with your actual:"
echo "      - cluster_id"
echo "      - environment_id"  
echo "      - organization_id"
echo "      - kafka_rest_endpoint"
echo "   3. Set your Confluent Cloud credentials"
echo "   4. Run: terraform apply -var-file=\"examples/data-driven.tfvars\""
echo
echo "🔗 Documentation:"
echo "   - README.md: Complete configuration guide"
echo "   - examples/data-driven.tfvars: Example configuration"
echo "   - SECRETS_MANAGEMENT.md: Credential setup guide"