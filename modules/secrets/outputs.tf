output "confluent_api_key" {
  description = "Confluent Cloud API Key"
  value       = local.confluent_api_key
  sensitive   = true
}

output "confluent_api_secret" {
  description = "Confluent Cloud API Secret"
  value       = local.confluent_api_secret
  sensitive   = true
}

output "secret_backend_used" {
  description = "The secret backend that was used"
  value       = var.secret_backend
} 