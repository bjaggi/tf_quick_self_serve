# Confluent Metadata Configuration Structure

This directory contains environment-specific configurations for your Confluent Cloud infrastructure, organized by component type and format.

## Directory Structure

```
confluent_metadata/
├── schemas/                 # AVRO schema files (shared across environments)
│   ├── user-events-value.avsc
│   ├── order-events-value.avsc
│   └── payment-events-value.avsc
├── dev/
│   ├── config.yaml          # Master configuration file (legacy format)
│   ├── yaml/                # Component-specific YAML configurations
│   │   ├── topics.yaml
│   │   ├── schemas.yaml
│   │   ├── rbac.yaml
│   │   ├── service-accounts.yaml
│   │   └── consumer-groups.yaml
│   └── json/                # Component-specific JSON configurations
│       ├── topics.json
│       ├── schemas.json
│       ├── rbac.json
│       ├── service-accounts.json
│       └── consumer-groups.json
├── uat/
│   ├── config.yaml
│   ├── yaml/ (same structure as dev)
│   └── json/ (same structure as dev)
├── prod/
│   ├── config.yaml
│   ├── yaml/ (same structure as dev)
│   └── json/ (same structure as dev)
└── README.md               # This file
```

## Configuration Formats

### Legacy Format (config.yaml)
The main `config.yaml` files in each environment contain all configurations in a single file. This format is still supported for backward compatibility.

### Component-Specific Formats
Components are now split into separate files for better organization:

1. **topics.yaml/topics.json** - Kafka topic configurations
2. **schemas.yaml/schemas.json** - Schema Registry configurations
3. **rbac.yaml/rbac.json** - RBAC bindings and ACL configurations
4. **service-accounts.yaml/service-accounts.json** - Service account definitions
5. **consumer-groups.yaml/consumer-groups.json** - Consumer group configurations

## Usage Patterns

### YAML Format (Recommended for new configurations)
- Human-readable and easy to edit
- Great for version control and code reviews
- Supports comments and documentation
- Use for creating new configurations from scratch

### JSON Format (Import/Export scenarios)
- Machine-readable format
- Ideal for importing from existing clusters
- Compatible with REST API responses
- Use when migrating from other Kafka management tools

## Environment-Specific Considerations

### DEV Environment
- Lower partition counts for cost efficiency
- Shorter retention periods
- Relaxed `min.insync.replicas` settings
- Used for development and testing

### UAT Environment  
- Similar to DEV but with UAT-prefixed resource names
- Used for user acceptance testing
- Configuration mirrors DEV for consistency

### PROD Environment
- Higher partition counts for scale
- Longer retention periods
- Stricter `min.insync.replicas` settings
- Includes identity pool configurations for production access

## Component Details

### Topics Configuration
Defines Kafka topics with:
- Partition counts
- Retention policies
- Cleanup policies
- Minimum in-sync replicas

### Schemas Configuration
Manages Schema Registry schemas:
- Schema format (AVRO, JSON, Protobuf)
- Schema file references (pointing to `confluent_metadata/schemas/`)
- Compatibility settings
- **Note**: Schema files are shared across environments in the `schemas/` subdirectory

### RBAC Configuration
Controls access permissions with two supported formats:

**Simplified Format (Recommended):**
```json
"rbac_bindings_simplified": [
  {
    "principal": "service-account-name",
    "role": "DeveloperWrite", 
    "resource_type": "Topic",
    "resource_name": "my-topic",
    "pattern_type": "LITERAL"
  }
]
```
**Note**: `environment_id` and `cluster_id` are automatically read from `environments/{env}.tfvars`

**Legacy Format (Backward Compatible):**
- Service account bindings via `principal_type` and `principal_name`
- CRN patterns for resource-specific access
- Role assignments (DeveloperRead, DeveloperWrite, EnvironmentAdmin)

### Service Accounts Configuration
Defines service accounts:
- Account names
- Descriptions
- Environment-specific naming conventions

### Consumer Groups Configuration
Manages consumer group settings:
- Associated topics
- Lag thresholds
- Offset reset policies
- Currently used for documentation (groups are auto-created by applications)

## Best Practices

1. **Choose the Right Format**
   - Use YAML for human-created configurations
   - Use JSON for programmatic imports/exports

2. **Environment Consistency**
   - Keep similar structures across environments
   - Use environment-specific prefixes where appropriate
   - Scale resources appropriately per environment

3. **Version Control**
   - Commit both YAML and JSON formats if both are used
   - Use clear commit messages for configuration changes
   - Review changes carefully, especially for production

4. **Security**
   - Don't store secrets in configuration files
   - Use proper RBAC patterns for least-privilege access
   - Review permission patterns regularly

## Migration from Legacy Format

If you're migrating from the single `config.yaml` format:

1. The Terraform configuration automatically reads from `config.yaml` if component-specific files don't exist
2. Component-specific files take precedence over `config.yaml` entries
3. You can migrate gradually by moving sections from `config.yaml` to component files
4. Remove sections from `config.yaml` once they're moved to component files

## Terraform Integration

The main Terraform configuration (`main.tf`) has been updated to:
- Read from `confluent_metadata` folder (instead of `config`)
- Support both legacy and component-specific formats
- Merge configurations appropriately
- Provide backward compatibility

All existing Terraform commands and workflows continue to work unchanged.