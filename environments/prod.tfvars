# Production Environment Variables
# Replace these values with your actual Confluent Cloud resources

environment        = "prod"
organization_id   = "fff39d13-91b7-444b-baa6-c0007e80e4d5"  # SERVICES - AMER NE
cluster_id        = "lkc-1qq535"  # Replace with your prod cluster ID
environment_id    = "env-7qv2p"  # Replace with your prod environment ID
schema_registry_id = "lsrc-j55zm" # Replace with your schema registry ID (optional)
schema_registry_rest_endpoint = "https://psrc-j55zm.us-central1.gcp.confluent.cloud" # Replace with your Schema Registry REST endpoint
kafka_rest_endpoint = "https://pkc-921jm.us-east-2.aws.confluent.cloud:443" # Replace with your cluster's REST endpoint

# Kafka Cluster API Credentials (for topic operations)
kafka_api_key    = "MNBFIOM6QF3RUGWM"    # Replace with your Kafka cluster API key
kafka_api_secret = "cfltDEn2/qP47yN18mjrznLnAFN49ur5Xz/FFm5GPZVEeDlyLA4wQ9WfvB2d6wNw" # Replace with your Kafka cluster API secret

# Schema Registry API Credentials (for schema operations) 
schema_registry_api_key    = "QCAVF7NOELXVNA2J"    # Replace with your Schema Registry API key
schema_registry_api_secret = "cfltUd+pADZqeV+b30o5TVNpyHXW8YptVCw0Gxdo0H/Z2JVQr2gQ7NBfqbw3eb2g" # Replace with your Schema Registry API secret

# Secret Management Configuration
# Choose your secret backend: environment_variables, aws_secrets_manager, azure_keyvault, hashicorp_vault, terraform_cloud
secret_backend = "aws_secrets_manager"  # Production typically uses external secret management

# AWS Secrets Manager (recommended for production)
aws_secret_name = "confluent-cloud-credentials-prod"

# Environment Variables (fallback, not recommended for production)
# secret_backend = "environment_variables" 
# confluent_api_key_env_var    = ""  # Auto-populated from environment
# confluent_api_secret_env_var = ""  # Auto-populated from environment
# Environment Variables (default method)
# These will be read from CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET environment variables
confluent_api_key_env_var    = "22RX4ZMU6SNYTDB5"
confluent_api_secret_env_var = "cflt0pqi44eN9XOrhdYzsQL7fT6AilDqE5twvH4VAmi3AhCGyhpkTkUDgu5dveyg"


# Azure Key Vault (uncomment if using)  
# secret_backend = "azure_keyvault"
# azure_keyvault_name = "your-keyvault-name"
# azure_resource_group_name = "your-resource-group"

# HashiCorp Vault (uncomment if using)
# secret_backend = "hashicorp_vault"
# vault_secret_path = "secret/confluent/prod"

# Terraform Cloud (uncomment if using)
# secret_backend = "terraform_cloud"
# These would be set as sensitive variables in your Terraform Cloud workspace 