# Production Environment Variables
# Replace these values with your actual Confluent Cloud resources

environment        = "prod"
organization_id   = "fff39d13-91b7-444b-baa6-c0007e80e4d5"  # SERVICES - AMER NE
cluster_id        = "lkc-zzzzzz"  # Replace with your prod cluster ID
environment_id    = "env-zzzzzz"  # Replace with your prod environment ID
schema_registry_id = "lsrc-zzzzzz" # Replace with your schema registry ID (optional)
kafka_rest_endpoint = "https://pkc-zzzzzz.region.provider.confluent.cloud:443" # Replace with your cluster's REST endpoint

# Kafka Cluster API Credentials (for topic and schema operations)
kafka_api_key    = "REPLACE_WITH_PROD_KAFKA_API_KEY"    # Replace with your Kafka cluster API key
kafka_api_secret = "REPLACE_WITH_PROD_KAFKA_API_SECRET" # Replace with your Kafka cluster API secret

# Secret Management Configuration
# Choose your secret backend: environment_variables, aws_secrets_manager, azure_keyvault, hashicorp_vault, terraform_cloud
secret_backend = "aws_secrets_manager"  # Production typically uses external secret management

# AWS Secrets Manager (recommended for production)
aws_secret_name = "confluent-cloud-credentials-prod"

# Environment Variables (fallback, not recommended for production)
# secret_backend = "environment_variables" 
# confluent_api_key_env_var    = ""  # Auto-populated from environment
# confluent_api_secret_env_var = ""  # Auto-populated from environment

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