# AWS S3 Backend Configuration
# Use this for production environments on AWS
# State files will be stored in S3 (simplified setup without DynamoDB locking)

terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"           # Replace with your S3 bucket name
    key            = "confluent-kafka/dev/terraform.tfstate"    # State file path within bucket
    region         = "us-west-2"                            # AWS region where bucket is located
    encrypt        = true                                   # Enable encryption at rest
    
    # Optional: Use KMS for additional encryption
    # kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
    
    # Optional: Server-side encryption configuration
    # server_side_encryption_configuration {
    #   rule {
    #     apply_server_side_encryption_by_default {
    #       sse_algorithm = "AES256"
    #     }
    #   }
    # }
  }
}

# Prerequisites:
# 1. S3 bucket for state storage with versioning enabled
# 2. AWS credentials configured (CLI, IAM role, or environment variables)

# Benefits:
# - Simple setup, just S3 bucket required
# - Team collaboration with shared state
# - Versioning and backup through S3
# - Encryption at rest and in transit
# - Cost-effective (~$0.50/month for typical usage)

# ⚠️  Note: No state locking (avoid concurrent terraform runs)

# Setup Commands:
# aws s3 mb s3://your-terraform-state-bucket
# aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled 