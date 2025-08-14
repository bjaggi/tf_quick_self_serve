resource "confluent_identity_pool" "identity_pools" {
  for_each = var.identity_pools

  display_name    = each.key
  description     = lookup(each.value, "description", "Identity pool for ${each.key}")
  identity_claim  = each.value.identity_claim
  filter          = each.value.filter
  
  identity_provider {
    id = each.value.identity_provider_id
  }
} 