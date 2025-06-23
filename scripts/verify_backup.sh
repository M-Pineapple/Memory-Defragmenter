#!/bin/bash

# Verify Memory Service Backup Script
# This script validates backup files to ensure they're readable and complete

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_PATH="/Users/rogers/GitHub/mcp-memory-data/backups"

echo "Memory Service Backup Verification"
echo "=================================="
echo ""

# Check if backup directory exists
if [ ! -d "$BACKUP_PATH" ]; then
    echo "❌ ERROR: Backup directory not found at $BACKUP_PATH"
    exit 1
fi

# Get the latest backup file
LATEST_BACKUP=$(ls -t "$BACKUP_PATH"/memory_backup_*.json 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ No backup files found"
    exit 1
fi

echo "📁 Latest backup: $(basename "$LATEST_BACKUP")"
echo "📊 File size: $(du -h "$LATEST_BACKUP" | cut -f1)"
echo ""

# Verify JSON structure
echo "🔍 Verifying JSON structure..."
if python3 -c "import json; json.load(open('$LATEST_BACKUP'))" 2>/dev/null; then
    echo "✅ JSON structure is valid"
else
    echo "❌ JSON structure is invalid!"
    exit 1
fi

# Extract and display backup metadata
echo ""
echo "📈 Backup Statistics:"
python3 <<EOF
import json
from datetime import datetime

with open('$LATEST_BACKUP', 'r') as f:
    data = json.load(f)
    
print(f"  Timestamp: {data.get('timestamp', 'Unknown')}")
print(f"  Total memories: {data.get('total_memories', 0)}")

# Count memories by type
if 'memories' in data:
    types = {}
    for memory in data['memories']:
        if 'metadata' in memory:
            mem_type = memory['metadata'].get('type', 'untyped')
            types[mem_type] = types.get(mem_type, 0) + 1
    
    print(f"\n📊 Memories by type:")
    for mem_type, count in sorted(types.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"  - {mem_type}: {count}")
    
    # Sample a memory to verify content
    if data['memories']:
        sample = data['memories'][0]
        print(f"\n🔍 Sample memory verification:")
        print(f"  ID: {sample.get('id', 'No ID')[:16]}...")
        print(f"  Has content: {'✓' if sample.get('document') else '✗'}")
        print(f"  Has metadata: {'✓' if sample.get('metadata') else '✗'}")
        print(f"  Content length: {len(sample.get('document', ''))}")
EOF

echo ""
echo "✅ Backup verification complete!"
