output "role_bindings" {
  description = "All RBAC role bindings (service accounts, identity pools, and simplified format)"
  value       = confluent_role_binding.bindings
}

output "service_account_role_bindings" {
  description = "Service account role bindings (legacy compatibility)"
  value       = {
    for key, binding in confluent_role_binding.bindings : key => binding
    if contains(keys(local.legacy_service_account_bindings), key)
  }
}

output "identity_pool_role_bindings" {
  description = "Identity pool role bindings (legacy compatibility)"
  value       = {
    for key, binding in confluent_role_binding.bindings : key => binding
    if contains(keys(local.legacy_identity_pool_bindings), key)
  }
}

output "simplified_role_bindings" {
  description = "Simplified format role bindings"
  value       = {
    for key, binding in confluent_role_binding.bindings : key => binding
    if contains(keys(local.simplified_bindings), key)
  }
} 