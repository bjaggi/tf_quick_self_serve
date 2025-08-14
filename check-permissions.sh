#!/bin/bash

echo "🔍 Checking API Key Permissions..."
echo ""

API_KEY=$(grep confluent_api_key_env_var environments/dev.tfvars | cut -d'"' -f2)

echo "Current Cloud API Key: ${API_KEY:0:8}..."
echo ""
echo "📋 Required Permissions for RBAC:"
echo "   ✅ Organization Administrator (recommended)"
echo "   ✅ Environment Administrator (minimum for your environment)"
echo ""
echo "🔗 Check/Update Permissions:"
echo "   1. Go to: https://confluent.cloud/"
echo "   2. Profile → Cloud API Keys"
echo "   3. Find key: ${API_KEY:0:8}..."
echo "   4. Verify it has Organization Administrator or Environment Administrator role"
echo ""
echo "🚨 Common Permission Issues:"
echo "   ❌ Developer role → Can create resources but NOT RBAC"
echo "   ❌ Operator role → Can manage resources but NOT RBAC"  
echo "   ✅ Environment Admin → Can manage RBAC for environment"
echo "   ✅ Organization Admin → Can manage RBAC for organization"
echo ""
echo "💡 Alternative: Create new API key with proper admin permissions"