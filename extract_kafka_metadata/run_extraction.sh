#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT=${1:-dev}
SCHEMA_SOURCE=${SCHEMA_SOURCE:-glue}
REPO_OWNER=bjaggi
REPO_NAME=acl-to-cc-rbac-utility
RELEASE_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
RELEASE_BASE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download"
RAW_BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main"

# Local cache/paths
CACHE_DIR_DEFAULT="$(pwd)/.vendor/${REPO_NAME}-release"
CACHE_DIR=${ACL_TO_CC_UTILITY_DIR:-$CACHE_DIR_DEFAULT}
RELEASE_DIR="$CACHE_DIR/release"
SCRIPTS_DIR="$CACHE_DIR/scripts/extract_msk_metadata"
EXTRACT_SCRIPT="$SCRIPTS_DIR/extract-msk-metadata.sh"
EXTRACTOR_JAR="$RELEASE_DIR/msk-to-confluent-cloud.jar"

GENERATED_DIR="$(pwd)/extract_kafka_metadata/generated_jsons"
LOG_BASE_DIR="$(pwd)/logs/extract/${ENVIRONMENT}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_BASE_DIR/extract_${TIMESTAMP}.log"
FULL_LOG_FILE="$LOG_BASE_DIR/extract_${TIMESTAMP}_full.log"

print_info() { echo -e "[INFO] $1" | tee -a "$LOG_FILE" "$FULL_LOG_FILE"; }
print_success() { echo -e "[SUCCESS] $1" | tee -a "$LOG_FILE" "$FULL_LOG_FILE"; }
print_error() { echo -e "[ERROR] $1" | tee -a "$LOG_FILE" "$FULL_LOG_FILE"; }

mkdir -p "$LOG_BASE_DIR" "$GENERATED_DIR" "$RELEASE_DIR" "$SCRIPTS_DIR"

echo "=== Extraction session started at $(date) ===" >> "$FULL_LOG_FILE"
echo "Environment: $ENVIRONMENT" >> "$FULL_LOG_FILE"
echo "Schema Source: $SCHEMA_SOURCE" >> "$FULL_LOG_FILE"
echo "Cache Dir: $CACHE_DIR" >> "$FULL_LOG_FILE"

# Helper: download file if not exists or size zero
_download_if_missing() {
  local url=$1
  local dest=$2
  if [ -s "$dest" ]; then
    print_info "Found cached: $(basename "$dest")"
    return 0
  fi
  print_info "Downloading: $url -> $dest"
  if ! curl -fsSL "$url" -o "$dest" 2>>"$FULL_LOG_FILE"; then
    print_error "Download failed: $url"
    return 1
  fi
  return 0
}

# Discover and download latest release JAR using GitHub API
_download_latest_jar() {
  print_info "Querying latest release assets via GitHub API"
  local api_json
  if ! api_json=$(curl -fsSL "$RELEASE_API_URL" 2>>"$FULL_LOG_FILE"); then
    print_error "Failed to query GitHub API for latest release"
    return 1
  fi
  # Extract all JAR asset URLs
  local jar_urls
  jar_urls=$(printf "%s" "$api_json" | grep -Eo 'browser_download_url"\s*:\s*"[^"]+\.jar"' | sed -E 's/.*"(https:[^"]+)"/\1/')
  if [ -z "$jar_urls" ]; then
    print_error "No .jar assets found in latest release"
    return 1
  fi
  # Prefer the msk-to-confluent-cloud jar, else first jar
  local preferred_url=""
  while IFS= read -r url; do
    case "$url" in
      *msk-to-confluent-cloud*.jar*) preferred_url="$url"; break;;
    esac
  done <<< "$jar_urls"
  if [ -z "$preferred_url" ]; then
    preferred_url=$(printf "%s\n" "$jar_urls" | head -1)
  fi
  print_info "Selected JAR: $preferred_url"
  local downloaded_name="$RELEASE_DIR/$(basename "$preferred_url")"
  _download_if_missing "$preferred_url" "$downloaded_name" || return 1
  # Normalize to expected name for upstream script
  cp -f "$downloaded_name" "$EXTRACTOR_JAR"
  print_info "Cached extractor at: $EXTRACTOR_JAR"
  return 0
}

if [ ! -s "$EXTRACTOR_JAR" ]; then
  if ! _download_latest_jar; then
    print_info "Falling back to raw repository JAR path"
    _download_if_missing "${RAW_BASE_URL}/release/msk-to-confluent-cloud.jar" "$EXTRACTOR_JAR" || {
      print_error "Could not obtain msk-to-confluent-cloud.jar from release or raw path"
      exit 1
    }
  fi
fi

# Fetch the extractor script from main branch (lightweight, no git clone)
_download_if_missing "${RAW_BASE_URL}/scripts/extract_msk_metadata/extract-msk-metadata.sh" "$EXTRACT_SCRIPT" || {
  print_error "Could not obtain extractor script"
  exit 1
}
chmod +x "$EXTRACT_SCRIPT"

# Ensure msk.config exists
if [ ! -f "$CACHE_DIR/msk.config" ]; then
  if [ -n "${MSK_CLUSTER_ARN:-}" ] && [ -n "${AWS_REGION:-}" ]; then
    print_info "Creating msk.config from environment variables"
    cat > "$CACHE_DIR/msk.config" <<EOF
cluster.arn=${MSK_CLUSTER_ARN}
aws.region=${AWS_REGION}
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
client.id=msk-acl-extractor
request.timeout.ms=30000
admin.request.timeout.ms=60000
EOF
  else
    # Try to fetch sample from repo raw
    _download_if_missing "${RAW_BASE_URL}/msk.config.sample" "$CACHE_DIR/msk.config.sample" || true
    if [ -f "$CACHE_DIR/msk.config.sample" ]; then
      print_info "Copying downloaded msk.config.sample to msk.config"
      cp "$CACHE_DIR/msk.config.sample" "$CACHE_DIR/msk.config"
    else
      print_error "msk.config not found and cannot be generated. Set MSK_CLUSTER_ARN and AWS_REGION or place msk.config in $CACHE_DIR"
      exit 1
    fi
  fi
fi

# Export required variables so upstream script can find artifacts in our cache
export MSK_UTILITY_BASE_DIR="$CACHE_DIR"
export MSK_RELEASE_DIR="$RELEASE_DIR"
export MSK_CONFIG_FILE="$CACHE_DIR/msk.config"

print_info "Running extractor via upstream script..."
echo "Command: $EXTRACT_SCRIPT --source-of-schemas ${SCHEMA_SOURCE}" >> "$FULL_LOG_FILE"
(
  cd "$CACHE_DIR"
  "$EXTRACT_SCRIPT" --source-of-schemas "${SCHEMA_SOURCE}"
) 2>&1 | tee -a "$FULL_LOG_FILE" "$LOG_FILE"

# Copy outputs back to repo
SRC_DIR="$CACHE_DIR/generated_jsons"
if [ -d "$SRC_DIR" ]; then
  print_info "Copying generated JSONs from $SRC_DIR to $GENERATED_DIR"
  rsync -a "$SRC_DIR/" "$GENERATED_DIR/" 2>&1 | tee -a "$FULL_LOG_FILE"
  print_success "Extraction complete. Files available in: $GENERATED_DIR"
else
  print_error "No generated_jsons directory found. Check logs for extractor errors."
  exit 1
fi

echo "=== Extraction session completed at $(date) ===" >> "$FULL_LOG_FILE"