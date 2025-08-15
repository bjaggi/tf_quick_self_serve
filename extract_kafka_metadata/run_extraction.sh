#!/bin/bash

# MSK ACL to Confluent Cloud RBAC Converter Script
# This script converts MSK ACLs from JSON format to Confluent Cloud RBAC format
# NO DOWNLOADING - JAR must be present in libs/ directory

set -e

# Default values - run without specific environment/cluster IDs
INPUT_FILE="generated_jsons/msk_jsons/msk_acls.json"
OUTPUT_FILE="generated_jsons/cc_jsons/cc_rbac.json"
ENVIRONMENT=""
CLUSTER_ID=""
VERBOSE=false

# Function to display help
show_help() {
    cat << EOF
MSK ACL to Confluent Cloud RBAC Converter

Usage: $0

Auto-run mode - no command line arguments needed!

The script will:
- Convert MSK ACLs to Confluent Cloud RBAC format
- Use default input/output paths
- Run without specific environment/cluster IDs

Files:
- Input:  msk_jsons/msk_acls.json
- Output: generated_jsons/cc_jsons/cc_rbac.json

Example:
    # Just run it - no options needed!
    $0

Requirements:
    - Java 11 or higher
    - msk-to-confluent-cloud.jar file in libs/ directory
    - Input JSON file with MSK ACL data

The script will:
1. Validate JAR file exists in libs/ directory
2. Run the ACL to RBAC conversion
3. Generate a Confluent Cloud RBAC JSON file
4. Display conversion summary

EOF
}

# Auto-run mode - no command line arguments needed
echo "Auto-run mode: Converting ACLs to RBAC without specific environment/cluster IDs"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_processing() {
    echo -e "${BLUE}[PROCESSING]${NC} $1"
}

show_conversion_summary() {
    if [[ -f "$OUTPUT_FILE" ]]; then
        print_info "Conversion Summary:"
        print_info "=================="
        print_info "Input file:  $INPUT_FILE"
        print_info "Output file: $OUTPUT_FILE"
        
        # Count role bindings if the file contains JSON
        if command -v jq &> /dev/null && [[ -s "$OUTPUT_FILE" ]]; then
            local role_count=$(jq -r '.roleBindings | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
            print_info "Role bindings created: $role_count"
        fi
        
        print_info "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    else
        print_warning "Output file not found: $OUTPUT_FILE"
    fi
}

check_prerequisites() {
    print_processing "Validating prerequisites..."
    
    # Check if Java is available
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed or not in PATH"
        print_info "Please install Java 11 or higher"
        exit 1
    fi
    
    # Check if JAR file exists in libs directory - NEVER DOWNLOAD
    if [[ ! -f "libs/msk-to-confluent-cloud.jar" ]]; then
        print_error "JAR file not found: libs/msk-to-confluent-cloud.jar"
        print_error "Please place the msk-to-confluent-cloud.jar file in the libs/ directory"
        print_error "NO DOWNLOADING will be attempted - JAR must be manually placed"
        exit 1
    fi
    
    # Check if input file exists
    if [[ ! -f "$INPUT_FILE" ]]; then
        print_error "Input file not found: $INPUT_FILE"
        print_error "Please ensure MSK ACL data exists at the specified path"
        exit 1
    fi
    
    print_success "All prerequisites validated - using JAR from libs/"
}

convert_acls_to_rbac() {
    print_processing "Converting ACLs to RBAC using Java..."
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    
    # Prepare Java command - ONLY use libs JAR, never download
    JAVA_CMD="java -jar libs/msk-to-confluent-cloud.jar convert"
    
    # Add required arguments
    JAVA_CMD="$JAVA_CMD --input-file \"$INPUT_FILE\""
    JAVA_CMD="$JAVA_CMD --output-file \"$OUTPUT_FILE\""
    
    # Add optional arguments
    if [[ "$DRY_RUN" == "true" ]]; then
        JAVA_CMD="$JAVA_CMD --dry-run"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        JAVA_CMD="$JAVA_CMD --verbose"
    fi
    
    if [[ "$FORCE" == "true" ]]; then
        JAVA_CMD="$JAVA_CMD --force"
    fi
    
    # Skip environment and cluster ID parameters - let JAR use defaults
    # if [[ -n "$CLUSTER_ID" ]]; then
    #     JAVA_CMD="$JAVA_CMD --cluster-id \"$CLUSTER_ID\""
    # fi
    # 
    # if [[ -n "$ENVIRONMENT" ]]; then
    #     JAVA_CMD="$JAVA_CMD --environment-id \"$ENVIRONMENT\""
    # fi
    
    print_info "Executing: $JAVA_CMD"
    
    # Execute the conversion
    if eval "$JAVA_CMD"; then
        print_success "ACL to RBAC conversion completed successfully"
        
        # Show conversion summary if output file exists
        if [[ -f "$OUTPUT_FILE" ]]; then
            show_conversion_summary
        fi
        
        return 0
    else
        print_error "ACL to RBAC conversion failed"
        return 1
    fi
}

# Main execution
main() {
    print_info "MSK ACL to Confluent Cloud RBAC Converter"
    print_info "=========================================="
    print_info "Using JAR from libs/ directory (NO DOWNLOADING)"
    print_info "Running without specific environment/cluster IDs"
    print_info ""
    
    # Perform checks
    check_prerequisites
    
    # Convert ACLs to RBAC
    convert_acls_to_rbac
    
    print_success "All done! 🎉"
    print_info "Next steps:"
    print_info "1. Review the generated RBAC file: $OUTPUT_FILE"
    print_info "2. Validate the role bindings match your requirements"
    print_info "3. Apply the role bindings to your Confluent Cloud cluster"
    print_info "4. Test the permissions with your applications"
}

# Run main function
main