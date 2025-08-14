output "topics" {
  description = "Created Kafka topics"
  value       = confluent_kafka_topic.topics
} 