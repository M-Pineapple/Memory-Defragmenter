#!/bin/bash

echo "=== Testing Homebrew Python 3.11 ==="
/opt/homebrew/bin/python3.11 --version
echo ""
echo "Testing ChromaDB import:"
/opt/homebrew/bin/python3.11 -c "import chromadb; print('✅ ChromaDB is installed'); print(f'Location: {chromadb.__file__}')" 2>&1

echo ""
echo "=== If ChromaDB is not found, install it with: ==="
echo "/opt/homebrew/bin/python3.11 -m pip install chromadb"
