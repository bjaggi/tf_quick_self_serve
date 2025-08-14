locals {
  # Load environment-specific configuration from JSON files only
  config_base_path = "${var.config_path}/${var.environment}/json"
  
  # Read JSON files
  json_topics_file          = "${local.config_base_path}/topics.json"
  json_schemas_file         = "${local.config_base_path}/schemas.json"
  json_rbac_file            = "${local.config_base_path}/rbac.json"
  json_service_accounts_file = "${local.config_base_path}/service-accounts.json"
  json_consumer_groups_file = "${local.config_base_path}/consumer-groups.json"
  
  # Load JSON configurations directly (files are required to exist)
  json_topics_config          = jsondecode(file(local.json_topics_file))
  json_schemas_config         = jsondecode(file(local.json_schemas_file))
  json_rbac_config            = jsondecode(file(local.json_rbac_file))
  json_service_accounts_config = jsondecode(file(local.json_service_accounts_file))
  json_consumer_groups_config = jsondecode(file(local.json_consumer_groups_file))
  
  # Transform JSON arrays to maps for compatibility with existing modules
  # Convert service_accounts array to map
  json_service_accounts_map = {
    for sa in lookup(local.json_service_accounts_config, "service_accounts", []) :
    sa.name => {
      description = sa.description
    }
  }
  
  # Convert schemas array to map  
  json_schemas_map = {
    for schema in lookup(local.json_schemas_config, "schemas", []) :
    schema.name => {
      format      = schema.format
      schema_file = schema.schema_file
    }
  }
  
  # Extract configuration sections from JSON files
  yaml_topics                   = {} # Topics will use topics_json format instead
  yaml_topics_json              = local.json_topics_config
  yaml_service_accounts         = local.json_service_accounts_map
  yaml_identity_pools           = lookup(local.json_rbac_config, "identity_pools", {})
  yaml_rbac_bindings            = lookup(local.json_rbac_config, "rbac_bindings", {})
  yaml_rbac_bindings_simplified = lookup(local.json_rbac_config, "rbac_bindings_simplified", [])
  yaml_schemas                  = local.json_schemas_map
  
  # Transform data-driven configuration
  # Convert topics list to map format expected by the module
  data_driven_topics = length(var.topics) > 0 ? {
    for topic in var.topics :
    topic.name => {
      partitions = topic.partitions
      config     = topic.config
    }
  } : {}
  
  # Convert service account list to map format expected by the module
  data_driven_service_accounts = length(var.service_account_list) > 0 ? {
    for sa_name in var.service_account_list :
    sa_name => {
      description = "Service account for ${sa_name}"
    }
  } : {}
  
  # Generate RBAC bindings from topics_rbac configuration
  data_driven_rbac_bindings = length(var.topics_rbac) > 0 ? merge([
    for topic_rbac in var.topics_rbac : merge(
      # Producer bindings
      {
        for sa_name in topic_rbac.producer_sa_list :
        "${sa_name}-${topic_rbac.topic_name}-producer" => {
          principal_type = "service_account"
          principal_name = sa_name
          role_name      = "DeveloperWrite"
          crn_pattern    = "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=${topic_rbac.topic_name}"
        }
      },
      # Consumer bindings  
      {
        for sa_name in topic_rbac.consumer_sa_list :
        "${sa_name}-${topic_rbac.topic_name}-consumer" => {
          principal_type = "service_account"
          principal_name = sa_name
          role_name      = "DeveloperRead" 
          crn_pattern    = "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=${topic_rbac.topic_name}"
        }
      },
      # Producer and Consumer bindings
      {
        for sa_name in topic_rbac.producer_and_consumer_sa_list :
        "${sa_name}-${topic_rbac.topic_name}-producer" => {
          principal_type = "service_account"
          principal_name = sa_name
          role_name      = "DeveloperWrite"
          crn_pattern    = "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=${topic_rbac.topic_name}"
        }
      },
      {
        for sa_name in topic_rbac.producer_and_consumer_sa_list :
        "${sa_name}-${topic_rbac.topic_name}-consumer" => {
          principal_type = "service_account"
          principal_name = sa_name
          role_name      = "DeveloperRead"
          crn_pattern    = "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=${topic_rbac.topic_name}"
        }
      }
    )
  ]...) : {}
  
  # Final configuration - merge YAML and data-driven configs (data-driven takes precedence)
  topics                    = merge(local.yaml_topics, local.data_driven_topics)
  service_accounts          = merge(local.yaml_service_accounts, local.data_driven_service_accounts)
  identity_pools            = local.yaml_identity_pools
  rbac_bindings             = merge(local.yaml_rbac_bindings, local.data_driven_rbac_bindings)
  rbac_bindings_simplified  = local.yaml_rbac_bindings_simplified
  schemas                   = local.yaml_schemas
}

# Topics Module
module "topics" {
  source = "./modules/topics"
  
  cluster_id     = var.cluster_id
  environment_id = var.environment_id
  topics         = local.topics
  topics_json    = local.yaml_topics_json
}

# Service Accounts Module
module "service_accounts" {
  source = "./modules/service_accounts"
  
  environment_id   = var.environment_id
  service_accounts = local.service_accounts
}

# Identity Pools Module  
module "identity_pools" {
  source = "./modules/identity_pools"
  
  environment_id   = var.environment_id
  identity_pools   = local.identity_pools
}

# RBAC Module
module "rbac" {
  source = "./modules/rbac"
  
  cluster_id                = var.cluster_id
  environment_id            = var.environment_id
  organization_id           = var.organization_id
  rbac_bindings             = local.rbac_bindings
  rbac_bindings_simplified  = local.rbac_bindings_simplified
  service_accounts          = module.service_accounts.service_accounts
  identity_pools            = module.identity_pools.identity_pools
  
  depends_on = [
    module.topics,
    module.service_accounts,
    module.identity_pools
  ]
}

# Schemas Module
module "schemas" {
  source = "./modules/schemas"
  
  schema_registry_id = var.schema_registry_id
  schemas           = local.schemas
  
  count = var.schema_registry_id != "" ? 1 : 0
} 