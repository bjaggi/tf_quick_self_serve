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