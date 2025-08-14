resource "confluent_service_account" "service_accounts" {
  for_each = var.service_accounts

  display_name = each.key
  description  = lookup(each.value, "description", "Service account for ${each.key}")
} 