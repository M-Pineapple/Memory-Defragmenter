#!/bin/bash

# Memory Defragmenter ChromaDB Workflow Helper
# This script helps with the export/import process for ChromaDB

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHROMA_PATH="${CHROMA_PATH:-/Users/rogers/GitHub/mcp-memory-data/chroma_db}"
EXPORT_FILE="memory_export.db"

echo "Memory Defragmenter - ChromaDB Workflow"
echo "======================================"
echo ""
echo "ChromaDB Path: $CHROMA_PATH"
echo ""

# Function to check if Python dependencies are installed
check_dependencies() {
    echo "Checking Python dependencies..."
    python3 -c "import chromadb" 2>/dev/null || {
        echo "Error: chromadb not installed"
        echo "Run: pip3 install chromadb sentence-transformers"
        exit 1
    }
    echo "✓ Dependencies OK"
    echo ""
}

# Function to create manual backup
create_backup() {
    echo "Creating manual backup of Memory Service..."
    echo "----------------------------------------"
    
    # Check if Memory Service directory exists
    if [ ! -d "/Users/rogers/GitHub/mcp-memory-service" ]; then
        echo "Error: Memory Service not found at /Users/rogers/GitHub/mcp-memory-service"
        return 1
    fi
    
    # Run backup
    cd /Users/rogers/GitHub/mcp-memory-service
    source venv/bin/activate 2>/dev/null || {
        echo "Warning: Could not activate virtual environment"
    }
    
    python scripts/backup_memories.py || {
        echo "Warning: Backup script failed. Continuing anyway..."
    }
    
    cd "$SCRIPT_DIR/.."
    echo ""
}

# Function to export ChromaDB
export_chromadb() {
    # Create backup first
    create_backup
    
    echo "Step 1: Exporting ChromaDB to SQLite..."
    echo "--------------------------------------"
    python3 "$SCRIPT_DIR/export_chromadb.py" \
        --chroma-path "$CHROMA_PATH" \
        --output "$EXPORT_FILE"
    
    if [ -f "$EXPORT_FILE" ]; then
        echo ""
        echo "✓ Export successful: $EXPORT_FILE"
        echo ""
        # Get file size
        SIZE=$(ls -lh "$EXPORT_FILE" | awk '{print $5}')
        echo "Database size: $SIZE"
    else
        echo "Error: Export failed"
        exit 1
    fi
}

# Function to wait for optimization
wait_for_optimization() {
    echo ""
    echo "Step 2: Optimize with Memory Defragmenter"
    echo "----------------------------------------"
    echo "1. Open Memory Defragmenter app"
    echo "2. Open database: $EXPORT_FILE"
    echo "3. Run analysis and optimization"
    echo "4. Close the app when done"
    echo ""
    read -p "Press Enter when optimization is complete..."
}

# Function to import back to ChromaDB
import_to_chromadb() {
    echo ""
    echo "Step 3: Importing optimized data back to ChromaDB..."
    echo "---------------------------------------------------"
    
    # Check if optimized file exists
    if [ ! -f "$EXPORT_FILE" ]; then
        echo "Error: $EXPORT_FILE not found"
        exit 1
    fi
    
    # Ask about backup
    read -p "Create backup of existing ChromaDB? (Y/n): " -n 1 -r
    echo ""
    
    BACKUP_FLAG=""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Will create backup..."
    else
        BACKUP_FLAG="--no-backup"
        echo "Skipping backup (not recommended)"
    fi
    
    python3 "$SCRIPT_DIR/import_to_chromadb.py" "$EXPORT_FILE" \
        --chroma-path "$CHROMA_PATH" \
        $BACKUP_FLAG
    
    echo ""
    echo "✓ Import complete!"
}

# Function to clean up
cleanup() {
    echo ""
    read -p "Delete temporary export file? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$EXPORT_FILE"
        echo "✓ Cleaned up temporary files"
    fi
}

# Main workflow
main() {
    check_dependencies
    
    echo "This will help you optimize your Memory Service MCP database"
    echo ""
    read -p "Continue? (Y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    # Check if Memory Service is running
    if pgrep -f "mcp_memory_service" > /dev/null; then
        echo "⚠️  Warning: Memory Service appears to be running"
        echo "It's recommended to stop it before proceeding"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Please stop Memory Service and try again"
            exit 1
        fi
    fi
    
    export_chromadb
    wait_for_optimization
    import_to_chromadb
    cleanup
    
    echo ""
    echo "✅ Workflow complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart Memory Service MCP"
    echo "2. Test that memories are working correctly"
    echo "3. Keep backups until you're sure everything works"
}

# Run main function
main
