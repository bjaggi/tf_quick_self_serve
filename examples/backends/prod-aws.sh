#!/bin/bash

# Example: Production Environment with AWS S3 Backend
# Use this for production environments with team collaboration

echo "Setting up production environment with AWS S3 backend..."

# Validate AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS credentials not configured!"
    echo "Please run: aws configure"
    exit 1
fi

# Create S3 bucket (run once per AWS account)
read -p "Create S3 bucket? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    BUCKET_NAME="your-company-terraform-state"
    REGION="us-west-2"
    
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb s3://$BUCKET_NAME --region $REGION
    
    echo "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled
        
    echo "✅ S3 bucket setup complete!"
fi

# Update backend configuration with your bucket name
echo "Updating backend configuration..."
sed -i.bak "s/your-terraform-state-bucket/$BUCKET_NAME/g" tf_state_externalized/aws-s3.tf

# Initialize backend
./scripts/init-backend.sh aws-s3 prod

echo "✅ Backend initialized for production environment"
echo ""
echo "⚠️  Important: No state locking enabled"
echo "   → Avoid running terraform simultaneously from multiple locations"
echo "   → Consider coordination for team environments"
echo ""
echo "Next steps:"
echo "1. Configure secrets using AWS Secrets Manager"
echo "2. Update environments/prod.tfvars with your cluster details"
echo "3. Run: ./scripts/deploy.sh prod plan"
echo "4. Run: ./scripts/deploy.sh prod apply" 