# Extract Kafka Metadata (MSK)

This folder contains a wrapper to run the MSK metadata extractor from the external utility and copy the generated JSONs back into this repository.

Upstream utility and script:
- Repo: https://github.com/bjaggi/acl-to-cc-rbac-utility
- Script: ./scripts/extract_msk_metadata/extract-msk-metadata.sh

## What this does
- Downloads the latest release JAR and extractor script (no git clone)
- Requires msk.config in extract_kafka_metadata/ directory (mandatory)
- Runs the extractor script (supports Glue schema source by default)
- Copies generated JSONs into extract_kafka_metadata/generated_jsons/
- Saves logs under logs/extract/

## Prerequisites
- bash, curl
- Java (required by the upstream extractor)
- AWS credentials with permissions to MSK (and Glue if using Glue schema registry)
- **MANDATORY: Your `msk.config` file must be placed in the `extract_kafka_metadata/` directory**

## Usage
```bash
# 1. Place your msk.config file in extract_kafka_metadata/ directory
cp /path/to/your/msk.config extract_kafka_metadata/

# 2. Make the wrapper executable (first time only)
chmod +x extract_kafka_metadata/run_extraction.sh

# 3. Run for dev (default schema source: glue)
./extract_kafka_metadata/run_extraction.sh dev

# Customize schema source (e.g., none, glue)
SCHEMA_SOURCE=glue ./extract_kafka_metadata/run_extraction.sh dev

# Use a custom cache directory (optional)
ACL_TO_CC_UTILITY_DIR=/path/to/cache ./extract_kafka_metadata/run_extraction.sh dev
```

## Outputs
- Generated JSONs from the extractor are copied to:
  - extract_kafka_metadata/generated_jsons/
- Logs are written to:
  - logs/extract/{environment}/extract_YYYYMMDD_HHMMSS.log
  - logs/extract/{environment}/extract_YYYYMMDD_HHMMSS_full.log

## Notes
- The script requires msk.config to be present in extract_kafka_metadata/ directory
- If msk.config is not found, the script will immediately fail with an error
- AWS credentials and permissions are expected to be provided by your environment (env vars, profiles, roles, etc.)

## MSK Configuration Example
Your `msk.config` should contain MSK connection details:
```properties
cluster.arn=arn:aws:kafka:us-east-1:123456789012:cluster/my-cluster/abc-123
aws.region=us-east-1
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
bootstrap.servers=broker1:9098,broker2:9098,broker3:9098
```
