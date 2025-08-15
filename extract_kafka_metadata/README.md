# MSK ACL to Confluent Cloud RBAC Converter

This folder contains a script to convert MSK ACLs to Confluent Cloud RBAC format using the JAR utility.

Upstream utility:
- Repo: https://github.com/bjaggi/acl-to-cc-rbac-utility
- JAR: msk-to-confluent-cloud.jar

## What this does
- Uses pre-installed JAR file from libs/ directory (no downloading)
- Converts MSK ACLs from JSON format to Confluent Cloud RBAC format
- Takes input from generated_jsons/msk_jsons/msk_acls.json by default
- Outputs to generated_jsons/cc_jsons/cc_rbac.json by default
- Supports custom environment and cluster IDs

## Prerequisites
- bash
- Java 11 or higher (required by the ACL converter JAR)
- **MANDATORY: `msk-to-confluent-cloud.jar` file must be placed in the `libs/` directory**
- Input MSK ACL data in JSON format (default: generated_jsons/msk_jsons/msk_acls.json)

## Usage
```bash
# 1. Place the JAR file in libs/ directory
cp /path/to/msk-to-confluent-cloud.jar extract_kafka_metadata/libs/

# 2. Ensure you have MSK ACL data in JSON format
# Default input: generated_jsons/msk_jsons/msk_acls.json

# 3. Run with default settings
./run_extraction.sh

# 4. Run with custom environment and cluster IDs
./run_extraction.sh -e env-12345 -c lkc-67890

# 5. Run with custom input/output files
./run_extraction.sh -i my_acls.json -o my_rbac.json

# 6. Run with verbose logging
./run_extraction.sh -v -e env-production -c lkc-my-cluster
```

## Outputs
- Converted RBAC file: generated_jsons/cc_jsons/cc_rbac.json (default)
- Conversion summary with role binding count and file size
- Detailed logging for troubleshooting

## Notes
- The script requires msk-to-confluent-cloud.jar to be present in libs/ directory
- If JAR file is missing, the script will immediately fail with an error  
- The script runs the JAR directly without downloading any external dependencies
- Input MSK ACL JSON file must exist (default path or custom via -i option)
- Output directory will be created automatically if it doesn't exist

## Example MSK ACL Input Format
Your input JSON file should contain MSK ACL data like:
```json
{
  "acls": [
    {
      "resourceType": "Topic",
      "resourceName": "my-topic",
      "principal": "User:my-user",
      "operation": "Read",
      "permissionType": "Allow"
    }
  ]
}
```
