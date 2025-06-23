#!/bin/bash

echo "=== Checking Homebrew Python ==="
echo "Looking for: /opt/homebrew/bin/python3"

if [ -f "/opt/homebrew/bin/python3" ]; then
    echo "✅ File exists"
    ls -la /opt/homebrew/bin/python3
    echo ""
    echo "Testing execution:"
    /opt/homebrew/bin/python3 --version
    echo ""
    echo "Testing ChromaDB import:"
    /opt/homebrew/bin/python3 -c "import chromadb; print('✅ ChromaDB is available'); print(f'ChromaDB location: {chromadb.__file__}')"
else
    echo "❌ File does not exist"
    echo ""
    echo "Checking /opt/homebrew/bin directory:"
    ls -la /opt/homebrew/bin/ | grep python
fi

echo ""
echo "=== Let's install ChromaDB directly with the Homebrew Python ==="
echo "Run this command:"
echo "/opt/homebrew/bin/python3 -m pip install chromadb"
