# Local values to handle both formats
locals {
  # Helper to determine principal format
  principal_mappings = {
    for idx, binding in var.rbac_bindings_simplified : 
    idx => (
      contains(keys(var.service_accounts), binding.principal) ? 
        "User:${var.service_accounts[binding.principal].id}" :
        contains(keys(var.identity_pools), binding.principal) ?
        "User:${var.identity_pools[binding.principal].id}" :
        (startswith(binding.principal, "User:") ? binding.principal : "User:${binding.principal}")
    )
  }
  
  # Convert simplified format to internal format
  simplified_bindings = {
    for idx, binding in var.rbac_bindings_simplified : 
    "simplified-${idx}" => {
      principal   = local.principal_mappings[idx]
      role_name   = binding.role
      crn_pattern = (
        binding.resource_type == "Topic" ? 
        "crn://confluent.cloud/organization=${var.organization_id}/environment=${var.environment_id}/cloud-cluster=${var.cluster_id}/kafka=${var.cluster_id}/topic=${binding.resource_name}" :
        binding.resource_type == "Environment" ?
        "crn://confluent.cloud/organization=${var.organization_id}/environment=${var.environment_id}" :
        "crn://confluent.cloud/organization=${var.organization_id}/environment=${var.environment_id}/cloud-cluster=${var.cluster_id}/kafka=${var.cluster_id}"
      )
    }
  }
  
  # Legacy format bindings (for backward compatibility)
  legacy_service_account_bindings = {
    for binding_key, binding in var.rbac_bindings : binding_key => {
      principal   = "User:${var.service_accounts[binding.principal_name].id}"
      role_name   = binding.role_name
      crn_pattern = replace(
        replace(
          replace(
            replace(binding.crn_pattern, "organization=*", "organization=${var.organization_id}"),
            "environment=*", "environment=${var.environment_id}"
          ),
          "cloud-cluster=*", "cloud-cluster=${var.cluster_id}"
        ),
        "kafka=*", "kafka=${var.cluster_id}"
      )
    }
    if try(binding.principal_type == "service_account", false)
  }
  
  legacy_identity_pool_bindings = {
    for binding_key, binding in var.rbac_bindings : binding_key => {
      principal   = "User:${var.identity_pools[binding.principal_name].id}"
      role_name   = binding.role_name
      crn_pattern = replace(
        replace(
          replace(
            replace(binding.crn_pattern, "organization=*", "organization=${var.organization_id}"),
            "environment=*", "environment=${var.environment_id}"
          ),
          "cloud-cluster=*", "cloud-cluster=${var.cluster_id}"
        ),
        "kafka=*", "kafka=${var.cluster_id}"
      )
    }
    if try(binding.principal_type == "identity_pool", false)
  }
  
  # Merge all bindings
  all_bindings = merge(
    local.simplified_bindings,
    local.legacy_service_account_bindings,
    local.legacy_identity_pool_bindings
  )
}

# Unified role bindings resource
resource "confluent_role_binding" "bindings" {
  for_each = local.all_bindings

  principal   = each.value.principal
  role_name   = each.value.role_name
  crn_pattern = each.value.crn_pattern
} 