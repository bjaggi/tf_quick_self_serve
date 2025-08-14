variable "schema_registry_id" {
  description = "Schema Registry cluster ID"
  type        = string
}

variable "schemas" {
  description = "Map of schema configurations"
  type = map(object({
    format      = optional(string, "AVRO")
    schema_file = string # Path to schema file
  }))
  default = {}
} 