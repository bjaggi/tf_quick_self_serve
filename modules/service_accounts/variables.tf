variable "environment_id" {
  description = "Confluent environment ID"
  type        = string
}

variable "service_accounts" {
  description = "Map of service account configurations"
  type = map(object({
    description = optional(string)
  }))
  default = {}
} 