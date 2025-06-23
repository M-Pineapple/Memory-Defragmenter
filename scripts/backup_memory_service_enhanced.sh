#!/bin/bash

# Enhanced Memory Service MCP Backup Script with Monitoring
# This script performs backups and monitors their success

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"
ERROR_LOG="$LOG_DIR/backup_errors.log"
BACKUP_SUMMARY="$LOG_DIR/backup_summary.json"

# Environment setup
export MCP_MEMORY_CHROMA_PATH="/Users/rogers/GitHub/mcp-memory-data/chroma_db"
export MCP_MEMORY_BACKUPS_PATH="/Users/rogers/GitHub/mcp-memory-data/backups"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check if Memory Service is running
check_memory_service() {
    if pgrep -f "mcp-memory-service" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get database size
get_db_size() {
    if [ -d "$MCP_MEMORY_CHROMA_PATH" ]; then
        du -sh "$MCP_MEMORY_CHROMA_PATH" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Function to count memories (approximate)
count_memories() {
    if [ -d "$MCP_MEMORY_CHROMA_PATH" ]; then
        # Count .bin files as a rough estimate
        find "$MCP_MEMORY_CHROMA_PATH" -name "*.bin" 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Start backup process
log_message "INFO" "=== Starting Memory Service Backup ==="
log_message "INFO" "Database path: $MCP_MEMORY_CHROMA_PATH"
log_message "INFO" "Backup path: $MCP_MEMORY_BACKUPS_PATH"

# Check if database exists
if [ ! -d "$MCP_MEMORY_CHROMA_PATH" ]; then
    log_message "ERROR" "ChromaDB directory not found at $MCP_MEMORY_CHROMA_PATH"
    echo "ERROR: ChromaDB directory not found" >> "$ERROR_LOG"
    exit 1
fi

# Get pre-backup stats
PRE_DB_SIZE=$(get_db_size)
PRE_MEMORY_COUNT=$(count_memories)
SERVICE_RUNNING=$(check_memory_service && echo "Yes" || echo "No")

log_message "INFO" "Pre-backup stats:"
log_message "INFO" "  - Database size: $PRE_DB_SIZE"
log_message "INFO" "  - Approximate memory count: $PRE_MEMORY_COUNT"
log_message "INFO" "  - Memory Service running: $SERVICE_RUNNING"

# Navigate to Memory Service directory
cd /Users/rogers/GitHub/mcp-memory-service || {
    log_message "ERROR" "Failed to navigate to Memory Service directory"
    exit 1
}

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    log_message "ERROR" "Virtual environment not found. Please set up Memory Service first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate || {
    log_message "ERROR" "Failed to activate virtual environment"
    exit 1
}

# Run the backup script
log_message "INFO" "Running Memory Service backup script..."
BACKUP_START=$(date +%s)

python scripts/backup_memories.py 2>&1 | while IFS= read -r line; do
    log_message "BACKUP" "$line"
done

BACKUP_EXIT_CODE=${PIPESTATUS[0]}
BACKUP_END=$(date +%s)
BACKUP_DURATION=$((BACKUP_END - BACKUP_START))

if [ $BACKUP_EXIT_CODE -eq 0 ]; then
    log_message "SUCCESS" "Backup completed successfully in ${BACKUP_DURATION}s"
    
    # Find the latest backup file
    LATEST_BACKUP=$(ls -t "$MCP_MEMORY_BACKUPS_PATH"/memory_backup_*.json 2>/dev/null | head -1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
        BACKUP_NAME=$(basename "$LATEST_BACKUP")
        log_message "INFO" "Latest backup: $BACKUP_NAME (Size: $BACKUP_SIZE)"
        
        # Create summary JSON
        cat > "$BACKUP_SUMMARY" <<EOF
{
    "last_backup": {
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
        "file": "$BACKUP_NAME",
        "size": "$BACKUP_SIZE",
        "duration_seconds": $BACKUP_DURATION,
        "status": "success",
        "db_size": "$PRE_DB_SIZE",
        "memory_count": $PRE_MEMORY_COUNT,
        "service_running": "$SERVICE_RUNNING"
    }
}
EOF
    else
        log_message "WARNING" "Backup script succeeded but no backup file found"
    fi
else
    log_message "ERROR" "Backup failed with exit code $BACKUP_EXIT_CODE"
    echo "$(date): Backup failed with exit code $BACKUP_EXIT_CODE" >> "$ERROR_LOG"
    
    # Create error summary
    cat > "$BACKUP_SUMMARY" <<EOF
{
    "last_backup": {
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
        "status": "failed",
        "error_code": $BACKUP_EXIT_CODE,
        "duration_seconds": $BACKUP_DURATION
    }
}
EOF
fi

# Cleanup old backups (keep last 12 months)
log_message "INFO" "Checking for old backups to clean up..."
BACKUP_COUNT=$(ls "$MCP_MEMORY_BACKUPS_PATH"/memory_backup_*.json 2>/dev/null | wc -l)

if [ $BACKUP_COUNT -gt 12 ]; then
    log_message "INFO" "Found $BACKUP_COUNT backups, keeping only the last 12"
    ls -t "$MCP_MEMORY_BACKUPS_PATH"/memory_backup_*.json | tail -n +13 | while read -r old_backup; do
        log_message "INFO" "Removing old backup: $(basename "$old_backup")"
        rm "$old_backup"
    done
fi

# List all current backups
log_message "INFO" "Current backups:"
ls -lah "$MCP_MEMORY_BACKUPS_PATH"/memory_backup_*.json 2>/dev/null | while read -r line; do
    log_message "INFO" "  $line"
done

# Deactivate virtual environment
deactivate

log_message "INFO" "=== Backup process completed ==="
echo "" >> "$LOG_FILE"  # Add blank line for readability

# Return appropriate exit code
exit $BACKUP_EXIT_CODE
