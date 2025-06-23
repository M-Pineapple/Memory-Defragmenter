#!/bin/bash

# Manual backup script for Memory Service MCP

echo "Memory Service MCP - Manual Backup"
echo "=================================="
echo ""

# Set up environment
export MCP_MEMORY_CHROMA_PATH="/Users/rogers/GitHub/mcp-memory-data/chroma_db"
export MCP_MEMORY_BACKUPS_PATH="/Users/rogers/GitHub/mcp-memory-data/backups"

# Navigate to Memory Service directory
cd /Users/rogers/GitHub/mcp-memory-service

# Activate virtual environment
source venv/bin/activate

# Run the backup script
echo "Creating backup..."
python scripts/backup_memories.py

echo ""
echo "Backup complete! Check: $MCP_MEMORY_BACKUPS_PATH"
echo ""

# List backups
echo "Available backups:"
ls -la "$MCP_MEMORY_BACKUPS_PATH"
