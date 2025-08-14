# 📋 Logging and Audit Trail

This document provides comprehensive information about the automatic logging system built into the Confluent Kafka Infrastructure as Code solution.

## 🔍 Overview

All deployment and infrastructure operations are automatically logged with complete session details, providing:
- **Audit trails** for compliance and security
- **Troubleshooting context** for debugging issues
- **Performance tracking** for optimization
- **Team collaboration** through shared operation history

## 📁 Log Structure

### Directory Organization
```
logs/
├── dev/
│   ├── plan_20250805_143022.log          # Clean, human-readable output
│   ├── plan_20250805_143022_full.log     # Complete output with metadata
│   ├── apply_20250805_143045.log         # Clean deployment output
│   ├── apply_20250805_143045_full.log    # Full deployment output
│   └── destroy_20250805_150330_full.log  # Destruction operations
├── uat/
│   ├── plan_20250805_160000.log
│   └── apply_20250805_160115_full.log
└── prod/
    ├── plan_20250805_170000.log
    └── apply_20250805_170245_full.log
```

### File Naming Convention
- **Format**: `{action}_{YYYYMMDD_HHMMSS}.log` or `{action}_{YYYYMMDD_HHMMSS}_full.log`
- **Actions**: `plan`, `apply`, `destroy`, `show`, `state`
- **Timestamp**: UTC time when the operation started

### Log File Types

#### 1. Clean Logs (`{action}_{timestamp}.log`)
- **Purpose**: Human-readable output for quick review
- **Content**: Terraform output as displayed in terminal
- **Use Case**: Quick status checks and sharing results

#### 2. Full Logs (`{action}_{timestamp}_full.log`)
- **Purpose**: Complete operation details for troubleshooting
- **Content**: 
  - Session metadata (user, timestamp, environment, working directory)
  - Exact commands executed
  - Full stdout and stderr output
  - Exit codes for each operation
  - Start and end timestamps for each command

## 📊 What Gets Logged

### Session Metadata
```
=== Terraform plan started at Mon Aug  5 14:30:22 UTC 2025 ===
Environment: dev
Action: plan
Working Directory: /path/to/tf_quick_self_serve
User: developer
================================================
```

### Command Execution
```
=== Terraform Plan - Mon Aug  5 14:30:25 UTC 2025 ===
Command: terraform plan -var-file="environments/dev.tfvars" -out="dev.tfplan"
---
[Terraform output here]

Exit code: 0
=== End Terraform Plan - Mon Aug  5 14:30:45 UTC 2025 ===
```

### Supported Operations
- **`terraform init`**: Backend initialization
- **`terraform plan`**: Infrastructure planning
- **`terraform apply`**: Infrastructure deployment
- **`terraform destroy`**: Infrastructure destruction
- **`terraform show`**: State inspection
- **`terraform state list`**: Resource listing

## 🔍 Using Logs

### Quick Log Analysis
```bash
# View recent deployment activity
ls -la logs/dev/ | tail -10

# Check the latest deployment logs
tail -50 logs/dev/$(ls -t logs/dev/*_full.log | head -1)

# Find all errors in recent deployments
grep -i "error\|failed\|exception" logs/dev/*_full.log | tail -20
```

### Troubleshooting Commands
```bash
# Search for authentication issues
grep -r -i "unauthorized\|forbidden\|authentication" logs/

# Find network connectivity problems
grep -r -i "timeout\|connection\|network" logs/

# Look for resource conflicts
grep -r -i "already exists\|conflict\|duplicate" logs/

# Check for permission problems
grep -r -i "permission\|access denied\|rbac" logs/

# Find operations that failed
grep -r "Exit code: [^0]" logs/**/*_full.log
```

### Performance Analysis
```bash
# Find long-running operations
grep -r "started at\|completed at" logs/**/*_full.log | grep -E "(plan|apply)"

# Count operations by environment
ls logs/*/apply_*.log | cut -d'/' -f2 | sort | uniq -c

# Find peak usage times
grep -r "started at" logs/**/*_full.log | cut -d' ' -f5-7 | sort | uniq -c
```

## 📈 Best Practices

### For Developers
1. **Check logs after failed operations**: Always review `*_full.log` files for complete error context
2. **Share logs for support**: Include relevant log snippets when asking for help
3. **Monitor log growth**: Clean up old logs periodically in development environments

### For Operations Teams
1. **Archive production logs**: Set up log rotation and archival for compliance
2. **Monitor for patterns**: Use log aggregation tools to identify recurring issues
3. **Automate alerts**: Set up alerts for failed deployments based on exit codes

### For Compliance
1. **Audit trails**: Logs provide complete "who, what, when" records
2. **Change tracking**: All infrastructure changes are automatically documented
3. **Retention**: Consider your organization's log retention requirements

## 🛡️ Security Considerations

### What's Not Logged
- **Sensitive values**: API keys, passwords, and secrets are masked by Terraform
- **Variable values**: Only variable names are logged, not their values
- **Private keys**: Terraform provider authentication details are not exposed

### Access Control
- **File permissions**: Log files inherit system permissions
- **Directory access**: Ensure appropriate access controls on the `logs/` directory
- **Sensitive environments**: Consider restricted access for production logs

## 🔧 Configuration

### Log Location
- **Default**: `logs/{environment}/` relative to project root
- **Customization**: Modify `LOG_BASE_DIR` variable in deployment scripts
- **Environment separation**: Each environment gets its own log directory

### Retention
- **Automatic cleanup**: No automatic cleanup by default
- **Manual cleanup**: Remove old logs as needed
- **Archival**: Consider implementing log archival for long-term storage

### Integration
- **CI/CD pipelines**: Logs can be collected and stored by CI/CD systems
- **Log aggregation**: Forward logs to centralized logging systems
- **Monitoring**: Parse logs for metrics and alerting

## 🚀 Advanced Usage

### Log Analysis Scripts
```bash
#!/bin/bash
# deployment-summary.sh - Generate deployment summary

ENV=${1:-dev}
echo "=== Deployment Summary for $ENV ==="
echo "Recent operations:"
ls -lt logs/$ENV/*.log | head -10

echo "Recent failures:"
grep -l "Exit code: [^0]" logs/$ENV/*_full.log | head -5

echo "Average deployment time:"
# Extract timestamps and calculate averages
grep -r "started at\|completed at" logs/$ENV/apply_*_full.log | 
  # ... additional processing
```

### Integration with Monitoring
```bash
# Export metrics to monitoring system
grep "Exit code: 0" logs/**/*_full.log | wc -l  # Success count
grep "Exit code: [^0]" logs/**/*_full.log | wc -l  # Failure count
```

## 📚 Related Documentation

- [HOW_TO_RUN.md](HOW_TO_RUN.md) - Complete deployment guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [BACKEND_MANAGEMENT.md](BACKEND_MANAGEMENT.md) - State management
- [scripts/README.md](scripts/README.md) - Script documentation

## 🎯 Benefits Summary

- **🛡️ Audit Compliance**: Complete record of all infrastructure changes
- **🐛 Faster Debugging**: Full context for troubleshooting issues
- **📈 Performance Insights**: Track deployment times and patterns
- **🔄 Reproducibility**: Exact commands and outputs preserved
- **👥 Team Collaboration**: Shared understanding of operations
- **🚨 Proactive Monitoring**: Identify issues before they become problems