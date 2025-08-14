output "topics" {
  description = "Created Kafka topics"
  value = {
    for topic_name, topic in module.topics.topics : topic_name => {
      id             = topic.id
      topic_name     = topic.topic_name
      partitions     = topic.partitions_count
      config         = topic.config
    }
  }
}

output "service_accounts" {
  description = "Created service accounts"
  value = {
    for sa_name, sa in module.service_accounts.service_accounts : sa_name => {
      id           = sa.id
      display_name = sa.display_name
      description  = sa.description
    }
  }
}

output "identity_pools" {
  description = "Created identity pools"
  value = {
    for pool_name, pool in module.identity_pools.identity_pools : pool_name => {
      id             = pool.id
      display_name   = pool.display_name
      description    = pool.description
      identity_claim = pool.identity_claim
      filter         = pool.filter
    }
  }
}

output "rbac_bindings_summary" {
  description = "Summary of RBAC bindings created"
  value = {
    service_account_bindings = length(module.rbac.service_account_role_bindings)
    identity_pool_bindings   = length(module.rbac.identity_pool_role_bindings)
  }
}

output "schemas" {
  description = "Created schemas"
  value = var.schema_registry_id != "" ? {
    for schema_name, schema in module.schemas[0].schemas : schema_name => {
      id           = schema.id
      subject_name = schema.subject_name
      format       = schema.format
      version      = schema.version
    }
  } : {}
}

output "secret_backend_used" {
  description = "The secret management backend that was used"
  value       = module.secrets.secret_backend_used
} 