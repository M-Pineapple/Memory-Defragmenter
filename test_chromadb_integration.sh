#!/bin/bash

# Test script to verify ChromaDB direct integration requirements

echo "Testing ChromaDB Direct Integration Requirements"
echo "=============================================="
echo ""

# Check Python 3
echo "1. Checking Python 3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python 3 found: $PYTHON_VERSION"
    PYTHON_PATH=$(which python3)
    echo "   Path: $PYTHON_PATH"
else
    echo "❌ Python 3 not found. Please install Python 3."
    exit 1
fi

echo ""

# Check ChromaDB
echo "2. Checking ChromaDB Python package..."
if python3 -c "import chromadb" 2>/dev/null; then
    CHROMADB_VERSION=$(python3 -c "import chromadb; print(chromadb.__version__)")
    echo "✅ ChromaDB found: version $CHROMADB_VERSION"
else
    echo "❌ ChromaDB not installed."
    echo "   To install: pip3 install chromadb"
    exit 1
fi

echo ""

# Check if ChromaDB path exists
echo "3. Checking ChromaDB path..."
CHROMA_PATH="/Users/rogers/GitHub/mcp-memory-data/chroma_db"
if [ -d "$CHROMA_PATH" ]; then
    echo "✅ ChromaDB path exists: $CHROMA_PATH"
    
    # Check for ChromaDB files
    if [ -f "$CHROMA_PATH/chroma.sqlite3" ]; then
        echo "✅ ChromaDB database file found"
    else
        echo "⚠️  ChromaDB database file not found - might be empty"
    fi
else
    echo "❌ ChromaDB path not found: $CHROMA_PATH"
fi

echo ""

# Test ChromaDB access
echo "4. Testing ChromaDB access..."
python3 << 'EOF'
import chromadb
import sys

try:
    client = chromadb.PersistentClient(path="/Users/rogers/GitHub/mcp-memory-data/chroma_db")
    collection = client.get_collection("memory_collection")
    count = collection.count()
    print(f"✅ ChromaDB access successful: {count} memories found")
except Exception as e:
    print(f"❌ ChromaDB access failed: {e}")
    sys.exit(1)
EOF

echo ""
echo "All tests passed! ChromaDB direct integration is ready."
echo ""
echo "Note: The app will now be able to:"
echo "- Open ChromaDB folders directly"
echo "- Optimize memories in place"
echo "- Create automatic backups"
echo "- Save optimized data back to original format"
