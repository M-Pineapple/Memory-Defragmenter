#!/bin/bash

# Source and destination
SOURCE="/Users/rogers/GitHub/mcp-memory-data/chroma_db"
DEST="/Users/rogers/Desktop/chroma_db_test"

echo "=== Creating a proper copy of ChromaDB ==="

# Remove old copy if exists
if [ -d "$DEST" ]; then
    echo "Removing old copy..."
    rm -rf "$DEST"
fi

echo "Copying ChromaDB..."
cp -R "$SOURCE" "$DEST"

echo "Setting permissions..."
chmod -R 755 "$DEST"

echo "Listing new copy:"
ls -la "$DEST"

echo -e "\nTesting the copy with Python:"
/opt/homebrew/bin/python3.11 - << 'EOF'
import chromadb
import sys

try:
    client = chromadb.PersistentClient(path="/Users/rogers/Desktop/chroma_db_test")
    collection = client.get_collection("memory_collection")
    count = collection.count()
    print(f"✅ Success! Found {count} memories in the copy")
except Exception as e:
    print(f"❌ Error: {e}")
EOF
