#!/bin/bash

echo "=== Testing Python paths for ChromaDB ==="

# Test each Python path that the app checks
paths=(
    "/usr/bin/python3"
    "/usr/local/bin/python3"
    "/opt/homebrew/bin/python3"
    "/opt/local/bin/python3"
    "/usr/bin/python"
    "/usr/local/bin/python"
    "/opt/homebrew/bin/python"
    "/System/Library/Frameworks/Python.framework/Versions/Current/bin/python3"
)

for python_path in "${paths[@]}"; do
    if [ -f "$python_path" ]; then
        echo -e "\n--- Testing: $python_path ---"
        $python_path --version
        $python_path -c "import chromadb; print('✅ ChromaDB is installed')" 2>&1
    fi
done

echo -e "\n=== Which Python is pip3 using? ==="
which pip3
pip3 --version

echo -e "\n=== Where is ChromaDB installed? ==="
pip3 show chromadb | grep Location
