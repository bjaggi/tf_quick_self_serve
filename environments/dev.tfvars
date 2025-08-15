# Development Environment Variables
# Replace these values with your actual Confluent Cloud resources

environment        = "dev"
organization_id   = "fff39d13-91b7-444b-baa6-c0007e80e4d5"  # SERVICES - AMER NE
cluster_id        = "lkc-y316j"  # Replace with your dev cluster ID
environment_id    = "env-7qv2p"  # Replace with your dev environment ID
#schema_registry_id = "lsrc-xxxxxx" # Replace with your schema registry ID (optional)
kafka_rest_endpoint = "https://pkc-ep9mm.us-east-2.aws.confluent.cloud:443" # Replace with your cluster's REST endpoint

# Kafka Cluster API Credentials (for topic and schema operations)
kafka_api_key    = "VBXL6FWEEVMI3MAL"    # Replace with your Kafka cluster API key
kafka_api_secret = "8FFCR82Vn6txAknYbR8LuYbyR/7rkERs6qlgi22FaohrNyt8bsNwNpQUspa1e4JL" # Replace with your Kafka cluster API secret

# Secret Management Configuration
# Choose your secret backend: environment_variables, aws_secrets_manager, azure_keyvault, hashicorp_vault, terraform_cloud
secret_backend = "environment_variables"

# Environment Variables (default method)
# These will be read from CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET environment variables
confluent_api_key_env_var    = "22RX4ZMU6SNYTDB5"
confluent_api_secret_env_var = "cflt0pqi44eN9XOrhdYzsQL7fT6AilDqE5twvH4VAmi3AhCGyhpkTkUDgu5dveyg"

# AWS Secrets Manager (uncomment if using)
# secret_backend = "aws_secrets_manager"
# aws_secret_name = "confluent-cloud-credentials-dev"

# Azure Key Vault (uncomment if using)  
# secret_backend = "azure_keyvault"
# azure_keyvault_name = "your-keyvault-name"
# azure_resource_group_name = "your-resource-group"

# HashiCorp Vault (uncomment if using)
# secret_backend = "hashicorp_vault"
# vault_secret_path = "secret/confluent/dev"

# Terraform Cloud (uncomment if using)
# secret_backend = "terraform_cloud"
# These would be set as sensitive variables in your Terraform Cloud workspace 