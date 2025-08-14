# RBAC Configuration Formats

This document explains the two supported formats for RBAC (Role-Based Access Control) configurations.

## Simplified Format (Recommended)

The simplified format matches the output from Confluent Cloud APIs and CLI tools, making it easier to import existing configurations.

### JSON Format

```json
{
  "rbac_bindings_simplified": [
    {
      "principal": "user-service-dev",
      "role": "DeveloperWrite",
      "resource_type": "Topic",
      "resource_name": "user-events",
      "pattern_type": "LITERAL"
    },
    {
      "principal": "order-service-dev",
      "role": "DeveloperRead",
      "resource_type": "Topic",
      "resource_name": "user-events",
      "pattern_type": "LITERAL"
    }
  ]
}
```

### YAML Format

```yaml
rbac_bindings_simplified:
  - principal: "user-service-dev"
    role: "DeveloperWrite"
    resource_type: "Topic"
    resource_name: "user-events"
    pattern_type: "LITERAL"
  - principal: "order-service-dev"
    role: "DeveloperRead"
    resource_type: "Topic"
    resource_name: "user-events"
    pattern_type: "LITERAL"
```

### Field Descriptions

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| `principal` | Service account name, identity pool name, or full principal ID | ✅ | `"user-service-dev"` |
| `role` | Confluent Cloud role name | ✅ | `"DeveloperWrite"` |
| `resource_type` | Type of resource (`Topic`, `Environment`, `Cluster`) | ✅ | `"Topic"` |
| `resource_name` | Name of the specific resource or `*` for all | ✅ | `"user-events"` |
| `pattern_type` | Pattern matching type (usually `"LITERAL"`) | ✅ | `"LITERAL"` |

**Note**: `environment_id` and `cluster_id` are automatically read from the `environments/{env}.tfvars` file for the current environment.

## Legacy Format (Backward Compatible)

The legacy format uses CRN patterns and requires separate service account/identity pool lookups.

### JSON Format

```json
{
  "rbac_bindings": [
    {
      "name": "user-service-producer",
      "principal_type": "service_account",
      "principal_name": "user-service-dev",
      "role_name": "DeveloperWrite",
      "crn_pattern": "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=user-events"
    }
  ]
}
```

### YAML Format

```yaml
rbac_bindings:
  user-service-producer:
    principal_type: "service_account"
    principal_name: "user-service-dev"
    role_name: "DeveloperWrite"
    crn_pattern: "crn://confluent.cloud/organization=*/environment=*/cloud-cluster=*/kafka=*/topic=user-events"
```

## Common Use Cases

### Topic Access

**Give a service account write access to a specific topic:**
```json
{
  "principal": "my-producer-service",
  "role": "DeveloperWrite", 
  "resource_type": "Topic",
  "resource_name": "my-topic",
  "pattern_type": "LITERAL"
}
```

**Give a service account read access to multiple topics with a prefix:**
```json
{
  "principal": "my-consumer-service",
  "role": "DeveloperRead",
  "resource_type": "Topic", 
  "resource_name": "events.*",
  "pattern_type": "PREFIXED"
}
```

### Environment Access

**Give an identity pool admin access to an environment:**
```json
{
  "principal": "prod-admins",
  "role": "EnvironmentAdmin",
  "resource_type": "Environment",
  "resource_name": "*",
  "pattern_type": "LITERAL"
}
```

## Principal Types

The `principal` field can be:

1. **Service Account Name**: Matches a service account defined in `service_accounts`
2. **Identity Pool Name**: Matches an identity pool defined in `identity_pools` 
3. **Full Principal ID**: Direct Confluent principal (e.g., `"sa-123456"`)
4. **External Principal**: External service principal (e.g., `"jaggi-msk-role"`)

The module automatically:
- Looks up service account IDs from the `service_accounts` module
- Looks up identity pool IDs from the `identity_pools` module
- Adds the `"User:"` prefix if not already present
- Constructs proper CRN patterns from resource information

## Migration from Legacy Format

To migrate from legacy to simplified format:

1. Replace `rbac_bindings` with `rbac_bindings_simplified`
2. Convert each binding:
   - `principal_name` → `principal`
   - `role_name` → `role`
   - Parse `crn_pattern` to extract `resource_type` and `resource_name`
   - Add `pattern_type: "LITERAL"`

## Best Practices

1. **Use simplified format** for new configurations
2. **Group related permissions** in the same file
3. **Use descriptive principal names** that match your service accounts
4. **Use LITERAL pattern type** for specific resources
5. **Use PREFIXED pattern type** for resource patterns with wildcards
6. **Environment and cluster info** is automatically read from `environments/{env}.tfvars`