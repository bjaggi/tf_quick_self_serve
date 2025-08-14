#!/bin/bash

echo "🔍 Testing API Key Setup..."
echo ""

# Check if Cloud API keys are set
if [ -z "$CONFLUENT_CLOUD_API_KEY" ]; then
    echo "❌ CONFLUENT_CLOUD_API_KEY is not set"
    echo "   Export it: export CONFLUENT_CLOUD_API_KEY='your-cloud-api-key'"
else
    echo "✅ CONFLUENT_CLOUD_API_KEY is set (${CONFLUENT_CLOUD_API_KEY:0:8}...)"
fi

if [ -z "$CONFLUENT_CLOUD_API_SECRET" ]; then
    echo "❌ CONFLUENT_CLOUD_API_SECRET is not set"
    echo "   Export it: export CONFLUENT_CLOUD_API_SECRET='your-cloud-api-secret'"
else
    echo "✅ CONFLUENT_CLOUD_API_SECRET is set (${CONFLUENT_CLOUD_API_SECRET:0:8}...)"
fi

# Check Terraform variables
if [ -z "$TF_VAR_confluent_api_key_env_var" ]; then
    echo "❌ TF_VAR_confluent_api_key_env_var is not set"
    echo "   Export it: export TF_VAR_confluent_api_key_env_var=\$CONFLUENT_CLOUD_API_KEY"
else
    echo "✅ TF_VAR_confluent_api_key_env_var is set"
fi

if [ -z "$TF_VAR_confluent_api_secret_env_var" ]; then
    echo "❌ TF_VAR_confluent_api_secret_env_var is not set"  
    echo "   Export it: export TF_VAR_confluent_api_secret_env_var=\$CONFLUENT_CLOUD_API_SECRET"
else
    echo "✅ TF_VAR_confluent_api_secret_env_var is set"
fi

echo ""
echo "📋 From your tfvars file:"
echo "   Kafka API Key: $(grep kafka_api_key environments/dev.tfvars | head -1)"
echo "   Kafka REST Endpoint: $(grep kafka_rest_endpoint environments/dev.tfvars)"

echo ""
echo "🎯 Once all ✅ are shown, run:"
echo "   terraform plan -var-file='environments/dev.tfvars'"