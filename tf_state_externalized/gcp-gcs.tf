# GCP Cloud Storage Backend Configuration  
# Use this for production environments on GCP with team collaboration
# State files will be stored in Cloud Storage with automatic state locking

terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"           # Replace with your GCS bucket name
    prefix = "confluent-kafka/dev"                       # Prefix for state file path
    
    # Optional: Specify credentials file path
    # credentials = "/path/to/service-account-key.json"
    
    # Optional: Encryption with customer-managed keys
    # encryption_key = "projects/PROJECT_ID/locations/LOCATION/keyRings/RING_NAME/cryptoKeys/KEY_NAME"
  }
}

# Prerequisites:
# 1. GCS bucket for state storage with versioning enabled
# 2. Service account with appropriate permissions
# 3. GCP credentials configured (gcloud CLI, service account key, or metadata service)
# 4. Enable Cloud Storage API for your project

# Benefits:
# - Team collaboration with shared state
# - Built-in state locking (no additional resources needed)
# - Versioning and backup through GCS
# - Encryption at rest and in transit
# - Integration with GCP IAM
# - Cost-effective storage

# Setup Commands:
# gsutil mb gs://your-terraform-state-bucket
# gsutil versioning set on gs://your-terraform-state-bucket

# Required IAM permissions for service account:
# - Storage Object Admin (on the bucket)
# - Storage Legacy Bucket Reader (on the bucket)

# Example service account creation:
# gcloud iam service-accounts create terraform-state \
#   --display-name="Terraform State Management"
# 
# gcloud projects add-iam-policy-binding PROJECT_ID \
#   --member="serviceAccount:terraform-state@PROJECT_ID.iam.gserviceaccount.com" \
#   --role="roles/storage.objectAdmin" 