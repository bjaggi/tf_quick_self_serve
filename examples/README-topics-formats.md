# Topics Configuration Formats

This project supports two formats for defining Kafka topics: **YAML** and **JSON**. Both formats can be used in your environment configuration files.

## YAML Format (Recommended for New Configurations)

The YAML format is simpler and ideal for creating new topics from scratch. Use this in your `config/{environment}/config.yaml` file:

```yaml
topics:
  user-events:
    partitions: 3
    config:
      "cleanup.policy": "delete"
      "retention.ms": "604800000"  # 7 days
      "min.insync.replicas": "2"
  
  payment-events:
    partitions: 6
    config:
      "cleanup.policy": "delete"
      "retention.ms": "2592000000"  # 30 days
      "min.insync.replicas": "2"
```

### YAML Format Fields

- `partitions`: Number of partitions (required)
- `config`: Map of topic configuration properties (optional)

**Note:** Replication factor is determined by the Kafka cluster's default settings and cannot be overridden per topic in Confluent Cloud.

## JSON Format (For Importing Existing Topics)

The JSON format includes detailed cluster and partition information, making it ideal for importing configurations from existing Kafka clusters. Use this when you have exported topic configurations from another cluster:

```yaml
# In your config/{environment}/config.yaml file, replace the topics section with:
topics_json:
  {
    "topics": [
      {
        "internal": false,
        "name": "user-events",
        "partitions": 3,
        "replication_factor": 3,
        "is_internal": false,
        "partition_info": [
          {
            "partition": 0,
            "leader": "b-1.cluster.kafka.us-east-1.amazonaws.com:9098 (id: 1 rack: use1-az1)",
            "replicas": ["broker1", "broker2", "broker3"],
            "in_sync_replicas": ["broker1", "broker2", "broker3"]
          }
        ],
        "configurations": {
          "cleanup.policy": "delete",
          "retention.ms": "604800000",
          "min.insync.replicas": "2"
        }
      }
    ],
    "cluster_metadata": {
      "cluster_name": "my-cluster",
      "number_of_broker_nodes": 3,
      "cluster_arn": "arn:aws:kafka:us-east-1:123456789012:cluster/my-cluster/abc-123",
      "kafka_version": "2.8.1",
      "state": "ACTIVE",
      "region": "us-east-1",
      "instance_type": "kafka.m7g.large"
    },
    "topic_count": 1,
    "exported_at": "2025-01-27T12:00:00.000000000"
  }
```

### JSON Format Fields

#### Topics Array
Each topic object contains:
- `name`: Topic name (required)
- `partitions`: Number of partitions (required)
- `replication_factor`: Replication factor (optional)
- `internal`: Whether topic is internal (optional)
- `is_internal`: Duplicate internal flag (optional)
- `partition_info`: Array of partition details (optional, used for documentation)
- `configurations`: Map of topic configuration properties (optional)

#### Cluster Metadata (Optional)
- `cluster_name`: Name of the source cluster
- `number_of_broker_nodes`: Number of brokers
- `cluster_arn`: AWS ARN if applicable
- `kafka_version`: Kafka version
- `state`: Cluster state
- `region`: AWS region if applicable
- `instance_type`: Broker instance type

#### Additional Metadata (Optional)
- `topic_count`: Total number of topics
- `exported_at`: Export timestamp

## Usage Examples

### Example 1: Using YAML Format
```yaml
# config/dev/config.yaml
topics:
  events:
    partitions: 3
    config:
      "retention.ms": "604800000"
```

### Example 2: Using JSON Format
```yaml
# config/prod/config.yaml
topics_json:
  {
    "topics": [
      {
        "name": "events",
        "partitions": 12,
        "replication_factor": 3,
        "configurations": {
          "retention.ms": "2592000000",
          "min.insync.replicas": "2"
        }
      }
    ]
  }
```

## Format Selection Guidelines

**Use YAML format when:**
- Creating new topics from scratch
- You want a simple, readable configuration
- You don't need detailed partition/replica information

**Use JSON format when:**
- Importing topics from existing clusters
- You have complex partition layouts to preserve
- You want to document cluster metadata
- You're migrating from another Kafka management tool

## Complete Example Files

- See `examples/topics-import-example.json` for a full JSON format example
- See `config/dev/config.yaml` for YAML format examples

## Important Notes

1. **Only use one format per environment** - Don't mix `topics` and `topics_json` in the same config file
2. **JSON partition_info is optional** - The Terraform provider will handle partition assignment
3. **All optional fields can be omitted** - The module provides sensible defaults
4. **Configuration keys should be quoted** - Kafka config keys often contain dots and special characters