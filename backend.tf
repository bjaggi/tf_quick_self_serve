# Local Backend Configuration
# Use this for development environments or when you don't need remote state management
# State files will be stored locally on the machine running Terraform

terraform {
  backend "local" {
    # Path will be set dynamically by init-backend.sh script
    # Default fallback path for dev environment
    path = "./states/prod/terraform.tfstate"
  }
}

# Benefits:
# - Simple setup, no external dependencies
# - Fast state operations
# - No additional costs
# - Full control over state file

# Limitations:
# - No team collaboration (state not shared)
# - No state locking (concurrent execution issues)
# - Risk of state file loss if machine fails
# - No versioning or backup built-in

# Recommended for:
# - Individual development
# - Proof of concepts
# - Testing and experimentation
# - CI/CD environments with ephemeral workers (when combined with artifact storage)