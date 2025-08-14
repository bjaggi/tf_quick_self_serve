variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "cluster_id" {
  description = "Confluent Kafka cluster ID"
  type        = string
}

variable "environment_id" {
  description = "Confluent environment ID"
  type        = string
}

variable "organization_id" {
  description = "Confluent organization ID"
  type        = string
}

variable "schema_registry_id" {
  description = "Schema Registry cluster ID"
  type        = string
  default     = ""
}

variable "kafka_rest_endpoint" {
  description = "The REST endpoint of the Kafka cluster (e.g., https://pkc-xxxxxx.region.provider.confluent.cloud:443)"
  type        = string
}

variable "kafka_api_key" {
  description = "Kafka cluster API key (for cluster-level operations)"
  type        = string
  sensitive   = true
}

variable "kafka_api_secret" {
  description = "Kafka cluster API secret (for cluster-level operations)"
  type        = string
  sensitive   = true
}

variable "config_path" {
  description = "Path to environment configuration files"
  type        = string
  default     = "confluent_metadata"
}

# Secret Management Variables
variable "secret_backend" {
  description = "Secret management backend to use"
  type        = string
  default     = "environment_variables"
  validation {
    condition = contains([
      "environment_variables",
      "aws_secrets_manager", 
      "azure_keyvault",
      "hashicorp_vault",
      "terraform_cloud"
    ], var.secret_backend)
    error_message = "Secret backend must be one of: environment_variables, aws_secrets_manager, azure_keyvault, hashicorp_vault, terraform_cloud."
  }
}

# Environment Variables (default/fallback)
variable "confluent_api_key_env_var" {
  description = "Confluent Cloud API Key from environment variable"
  type        = string
  default     = ""
  sensitive   = true
}

variable "confluent_api_secret_env_var" {
  description = "Confluent Cloud API Secret from environment variable"
  type        = string
  default     = ""
  sensitive   = true
}

# AWS Secrets Manager
variable "aws_secret_name" {
  description = "AWS Secrets Manager secret name containing Confluent credentials"
  type        = string
  default     = ""
}

# Azure Key Vault
variable "azure_keyvault_name" {
  description = "Azure Key Vault name"
  type        = string
  default     = ""
}

variable "azure_resource_group_name" {
  description = "Azure Resource Group name containing the Key Vault"
  type        = string
  default     = ""
}

variable "azure_api_key_secret_name" {
  description = "Azure Key Vault secret name for Confluent API key"
  type        = string
  default     = "confluent-api-key"
}

variable "azure_api_secret_secret_name" {
  description = "Azure Key Vault secret name for Confluent API secret"
  type        = string
  default     = "confluent-api-secret"
}

# HashiCorp Vault
variable "vault_secret_path" {
  description = "HashiCorp Vault secret path containing Confluent credentials"
  type        = string
  default     = ""
}

# Terraform Cloud/Enterprise
variable "terraform_cloud_api_key" {
  description = "Confluent Cloud API Key from Terraform Cloud variable"
  type        = string
  default     = ""
  sensitive   = true
}

variable "terraform_cloud_api_secret" {
  description = "Confluent Cloud API Secret from Terraform Cloud variable"
  type        = string
  default     = ""
  sensitive   = true
}

# Data-driven configuration variables
variable "topics" {
  description = "List of topic configurations with name, partitions, and config"
  type = list(object({
    name       = string
    partitions = number
    config     = map(string)
  }))
  default = []
}

variable "service_account_list" {
  description = "List of service account names to create"
  type        = list(string)
  default     = []
}

variable "topics_rbac" {
  description = "List of RBAC configurations per topic"
  type = list(object({
    topic_name                        = string
    producer_sa_list                  = list(string)
    consumer_sa_list                  = list(string)
    producer_and_consumer_sa_list     = list(string)
  }))
  default = []
} 