# Local values to normalize both YAML and JSON formats
locals {
  # Convert JSON format to normalized map if topics_json is provided
  json_topics = length(var.topics_json.topics) > 0 ? {
    for topic in var.topics_json.topics : topic.name => {
      partitions         = topic.partitions
      replication_factor = topic.replication_factor
      config            = topic.configurations
    }
  } : {}
  
  # Use JSON topics if provided, otherwise use YAML topics
  normalized_topics = length(var.topics_json.topics) > 0 ? local.json_topics : var.topics
}

resource "confluent_kafka_topic" "topics" {
  for_each = local.normalized_topics

  kafka_cluster {
    id = var.cluster_id
  }
  
  topic_name       = each.key
  partitions_count = lookup(each.value, "partitions", 1)
  
  config = lookup(each.value, "config", {})

  lifecycle {
    prevent_destroy = true
  }
} 