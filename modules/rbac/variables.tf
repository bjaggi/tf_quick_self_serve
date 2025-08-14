variable "cluster_id" {
  description = "Confluent Kafka cluster ID"
  type        = string
}

variable "environment_id" {
  description = "Confluent environment ID"
  type        = string
}

variable "organization_id" {
  description = "Confluent organization ID"
  type        = string
}

variable "rbac_bindings" {
  description = "RBAC binding configurations - supports both legacy and simplified formats"
  type = any
  default = {}
}

variable "rbac_bindings_simplified" {
  description = "Simplified RBAC binding configurations (new format)"
  type = list(object({
    principal      = string # Principal name (e.g., "jaggi-msk-role")
    role          = string # Role name (e.g., "DeveloperWrite")
    resource_type = string # Resource type (e.g., "Topic")
    resource_name = string # Resource name (e.g., "test_w")
    pattern_type  = string # Pattern type (e.g., "LITERAL")
  }))
  default = []
}

variable "service_accounts" {
  description = "Service accounts from service_accounts module"
  type        = any
  default     = {}
}

variable "identity_pools" {
  description = "Identity pools from identity_pools module"
  type        = any
  default     = {}
} 