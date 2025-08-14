variable "environment_id" {
  description = "Confluent environment ID"
  type        = string
}

variable "identity_pools" {
  description = "Map of identity pool configurations"
  type = map(object({
    description           = optional(string)
    identity_claim        = string
    filter                = string
    identity_provider_id  = string
  }))
  default = {}
} 