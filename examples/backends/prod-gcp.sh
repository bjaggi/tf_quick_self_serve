#!/bin/bash

# Example: Production Environment with GCP Cloud Storage Backend
# Use this for production environments on GCP with team collaboration

echo "Setting up production environment with GCP Cloud Storage backend..."

# Validate GCP credentials
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 >/dev/null 2>&1; then
    echo "Error: GCP credentials not configured!"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No GCP project configured!"
    echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using GCP project: $PROJECT_ID"

# Create GCS bucket (run once per GCP project)
read -p "Create GCS bucket for Terraform state? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    BUCKET_NAME="${PROJECT_ID}-terraform-state"
    REGION="us-central1"
    
    echo "Creating GCS bucket: $BUCKET_NAME"
    gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$BUCKET_NAME
    
    echo "Enabling versioning on GCS bucket..."
    gsutil versioning set on gs://$BUCKET_NAME
    
    echo "Setting up bucket permissions..."
    # Create service account for Terraform
    gcloud iam service-accounts create terraform-state \
        --display-name="Terraform State Management" \
        --project=$PROJECT_ID
    
    # Grant storage permissions
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:terraform-state@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/storage.objectAdmin"
    
    echo "GCS bucket created: $BUCKET_NAME"
fi

# Update backend configuration with your bucket name
echo "Updating backend configuration..."
sed -i.bak "s/your-terraform-state-bucket/$BUCKET_NAME/g" tf_state_externalized/gcp-gcs.tf

# Initialize backend
./scripts/init-backend.sh gcp-gcs prod

echo "Backend initialized for production environment"
echo "Next steps:"
echo "1. Configure secrets using GCP Secret Manager or other method"
echo "2. Update environments/prod.tfvars with your cluster details"
echo "3. Run: ./scripts/deploy.sh prod plan"
echo "4. Run: ./scripts/deploy.sh prod apply" 