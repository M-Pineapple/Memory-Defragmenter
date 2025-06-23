#!/bin/bash

# Backup Health Check Script
# Run this to check the status of your backups

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
BACKUP_SUMMARY="$LOG_DIR/backup_summary.json"
BACKUP_PATH="/Users/rogers/GitHub/mcp-memory-data/backups"

echo "Memory Service Backup Health Check"
echo "=================================="
echo ""

# Check if backup directory exists
if [ ! -d "$BACKUP_PATH" ]; then
    echo "❌ ERROR: Backup directory not found at $BACKUP_PATH"
    exit 1
fi

# Check last backup status from summary
if [ -f "$BACKUP_SUMMARY" ]; then
    echo "📊 Last Backup Summary:"
    echo "----------------------"
    
    # Parse JSON manually (works on macOS without jq)
    LAST_STATUS=$(grep '"status":' "$BACKUP_SUMMARY" | cut -d'"' -f4)
    LAST_TIMESTAMP=$(grep '"timestamp":' "$BACKUP_SUMMARY" | cut -d'"' -f4)
    LAST_FILE=$(grep '"file":' "$BACKUP_SUMMARY" | cut -d'"' -f4)
    LAST_SIZE=$(grep '"size":' "$BACKUP_SUMMARY" | cut -d'"' -f4)
    
    if [ "$LAST_STATUS" = "success" ]; then
        echo "✅ Status: SUCCESS"
    else
        echo "❌ Status: FAILED"
    fi
    
    echo "📅 Timestamp: $LAST_TIMESTAMP"
    echo "📁 File: $LAST_FILE"
    echo "💾 Size: $LAST_SIZE"
    echo ""
else
    echo "⚠️  No backup summary found"
    echo ""
fi

# List recent backups
echo "📦 Recent Backups:"
echo "-----------------"
ls -lht "$BACKUP_PATH"/memory_backup_*.json 2>/dev/null | head -5 | while read -r line; do
    echo "  $line"
done

# Check backup age
if [ -n "$LAST_TIMESTAMP" ]; then
    # Convert timestamps to seconds since epoch
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_TIMESTAMP" +%s 2>/dev/null)
        CURRENT_EPOCH=$(date +%s)
    else
        # Linux date command
        LAST_EPOCH=$(date -d "$LAST_TIMESTAMP" +%s 2>/dev/null)
        CURRENT_EPOCH=$(date +%s)
    fi
    
    if [ -n "$LAST_EPOCH" ]; then
        AGE_SECONDS=$((CURRENT_EPOCH - LAST_EPOCH))
        AGE_DAYS=$((AGE_SECONDS / 86400))
        
        echo ""
        echo "⏰ Backup Age: $AGE_DAYS days"
        
        if [ $AGE_DAYS -gt 35 ]; then
            echo "⚠️  WARNING: Last backup is more than 35 days old!"
        elif [ $AGE_DAYS -gt 31 ]; then
            echo "⚠️  Notice: Last backup is more than a month old"
        else
            echo "✅ Backup is recent"
        fi
    fi
fi

# Check if cron job exists
echo ""
echo "🔄 Cron Job Status:"
echo "------------------"
if crontab -l 2>/dev/null | grep -q "backup_memory_service"; then
    echo "✅ Cron job is configured"
    echo "   Schedule:"
    crontab -l | grep "backup_memory_service" | sed 's/^/   /'
else
    echo "❌ No cron job found for automatic backups"
    echo "   To set up monthly backups, run:"
    echo "   crontab -e"
    echo "   Then add:"
    echo "   0 2 1 * * cd \"$PROJECT_DIR\" && ./scripts/backup_memory_service_enhanced.sh"
fi

echo ""
echo "Done!"
