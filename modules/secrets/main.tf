# Secrets Module - Supports multiple secret management backends
# Supports: Environment Variables, AWS Secrets Manager, Azure Key Vault, HashiCorp Vault, Terraform Cloud

locals {
  # Determine which secret backend to use
  use_aws_secrets    = var.secret_backend == "aws_secrets_manager"
  use_azure_keyvault = var.secret_backend == "azure_keyvault"
  use_hashicorp_vault = var.secret_backend == "hashicorp_vault"
  use_terraform_cloud = var.secret_backend == "terraform_cloud"
  use_env_vars       = var.secret_backend == "environment_variables" || var.secret_backend == ""
}

# AWS Secrets Manager - Commented out to avoid provider initialization when not needed
# Uncomment only when using secret_backend = "aws_secrets_manager"

# data "aws_secretsmanager_secret" "confluent_credentials" {
#   count = local.use_aws_secrets ? 1 : 0
#   name  = var.aws_secret_name
# }

# data "aws_secretsmanager_secret_version" "confluent_credentials" {
#   count     = local.use_aws_secrets ? 1 : 0
#   secret_id = data.aws_secretsmanager_secret.confluent_credentials[0].id
# }

# Azure Key Vault - Commented out to avoid provider initialization when not needed
# Uncomment only when using secret_backend = "azure_keyvault"

# data "azurerm_key_vault" "confluent_vault" {
#   count               = local.use_azure_keyvault ? 1 : 0
#   name                = var.azure_keyvault_name
#   resource_group_name = var.azure_resource_group_name
# }

# data "azurerm_key_vault_secret" "confluent_api_key" {
#   count        = local.use_azure_keyvault ? 1 : 0
#   name         = var.azure_api_key_secret_name
#   key_vault_id = data.azurerm_key_vault.confluent_vault[0].id
# }

# data "azurerm_key_vault_secret" "confluent_api_secret" {
#   count        = local.use_azure_keyvault ? 1 : 0
#   name         = var.azure_api_secret_secret_name
#   key_vault_id = data.azurerm_key_vault.confluent_vault[0].id
# }

# HashiCorp Vault - Commented out to avoid provider initialization when not needed
# Uncomment only when using secret_backend = "hashicorp_vault"

# data "vault_generic_secret" "confluent_credentials" {
#   count = local.use_hashicorp_vault ? 1 : 0
#   path  = var.vault_secret_path
# }

# Terraform Cloud Variables (accessed via variables)
# These would be set as sensitive variables in Terraform Cloud workspace

locals {
  # For development with local backend, use only environment variables
  # When using external secret backends, uncomment the respective data sources above
  
  confluent_api_key = (
    # Comment out until you need external secret management:
    # local.use_aws_secrets ? jsondecode(data.aws_secretsmanager_secret_version.confluent_credentials[0].secret_string)["api_key"] :
    # local.use_azure_keyvault ? data.azurerm_key_vault_secret.confluent_api_key[0].value :
    # local.use_hashicorp_vault ? data.vault_generic_secret.confluent_credentials[0].data["api_key"] :
    local.use_terraform_cloud ? var.terraform_cloud_api_key :
    var.confluent_api_key_env_var
  )
  
  confluent_api_secret = (
    # Comment out until you need external secret management:
    # local.use_aws_secrets ? jsondecode(data.aws_secretsmanager_secret_version.confluent_credentials[0].secret_string)["api_secret"] :
    # local.use_azure_keyvault ? data.azurerm_key_vault_secret.confluent_api_secret[0].value :
    # local.use_hashicorp_vault ? data.vault_generic_secret.confluent_credentials[0].data["api_secret"] :
    local.use_terraform_cloud ? var.terraform_cloud_api_secret :
    var.confluent_api_secret_env_var
  )
} 