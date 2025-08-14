# Extract Kafka Metadata (MSK)

This folder contains a wrapper to run the MSK metadata extractor from the external utility and copy the generated JSONs back into this repository.

Upstream utility and script:
- Repo: https://github.com/bjaggi/acl-to-cc-rbac-utility
- Script: ./scripts/extract_msk_metadata/extract-msk-metadata.sh

## What this does
- Downloads the latest release JAR and extractor script (no git clone)
- Ensures an msk.config exists (creates one from env if possible)
- Runs the extractor script (supports Glue schema source by default)
- Copies generated JSONs into extract_kafka_metadata/generated_jsons/
- Saves logs under logs/extract/

## Prerequisites
- bash, curl
- Java (required by the upstream extractor)
- AWS credentials with permissions to MSK (and Glue if using Glue schema registry)
- Optional env vars:
  - AWS_REGION (recommended)
  - MSK_CLUSTER_ARN (used to auto-generate msk.config)

## Usage
```bash
# Make the wrapper executable (first time only)
chmod +x extract_kafka_metadata/run_extraction.sh

# Run for dev (default schema source: glue)
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
- If msk.config is not present in the cache directory, the wrapper will:
  - create one using MSK_CLUSTER_ARN and AWS_REGION if both are set; or
  - download msk.config.sample and copy to msk.config if available; otherwise it will fail with guidance
- AWS credentials and permissions are expected to be provided by your environment (env vars, profiles, roles, etc.)
