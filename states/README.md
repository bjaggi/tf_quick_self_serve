# Terraform State Directory

This directory contains organized Terraform state files by environment.

## Directory Structure

```
states/
├── dev/          # Development environment state files
├── uat/          # UAT environment state files  
├── prod/         # Production environment state files
└── README.md     # This file
```

## Files in Each Environment Directory

- `terraform.tfstate` - Current state file
- `terraform.tfstate.backup` - Previous state backup (auto-generated)
- `*.tfplan` - Plan files from `terraform plan` operations

## Benefits of Organized State Structure

1. **Clear Separation**: Each environment has its own isolated state
2. **Clean Root Directory**: No state files cluttering the main project folder
3. **Easy Backup**: Simple to backup or archive state files by environment
4. **Team Collaboration**: Easier to manage different environment states
5. **Debugging**: Faster to locate and examine environment-specific state

## Backend Configuration

The backend configuration automatically points to the correct state file based on environment:
- **Local**: `./states/{env}/terraform.tfstate`
- **AWS S3**: `confluent-kafka/{env}/terraform.tfstate`
- **GCP GCS**: `confluent-kafka/{env}/default.tfstate`
- **Azure Storage**: `confluent-kafka/{env}/terraform.tfstate`

## Usage

When using the deployment scripts, state files are automatically managed in this structure:

```bash
# State will be stored in states/dev/
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply

# State will be stored in states/prod/
./scripts/deploy.sh prod plan
./scripts/deploy.sh prod apply
```