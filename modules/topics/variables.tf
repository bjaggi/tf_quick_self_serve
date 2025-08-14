variable "cluster_id" {
  description = "Confluent Kafka cluster ID"
  type        = string
}

variable "environment_id" {
  description = "Confluent environment ID"
  type        = string
}

variable "topics" {
  description = "Topic configurations - supports both YAML map format and JSON array format"
  type = any
  default = {}
}

variable "topics_json" {
  description = "JSON format topics configuration (alternative to topics variable)"
  type = object({
    topics = optional(list(object({
      internal            = optional(bool, false)
      name               = string
      partitions         = optional(number, 1)
      replication_factor = optional(number, 3)
      is_internal        = optional(bool, false)
      partition_info     = optional(list(any), [])
      configurations     = optional(map(string), {})
    })), [])
    cluster_metadata = optional(object({
      cluster_name           = optional(string)
      number_of_broker_nodes = optional(number)
      cluster_arn           = optional(string)
      kafka_version         = optional(string)
      state                 = optional(string)
      region                = optional(string)
      instance_type         = optional(string)
    }), {})
    topic_count  = optional(number)
    exported_at  = optional(string)
  })
  default = {
    topics = []
  }
} 