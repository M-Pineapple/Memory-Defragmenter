#!/bin/bash

# Install ChromaDB and dependencies for Memory Defragmenter
echo "Installing ChromaDB and dependencies..."

# Check if pip3 is available
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Please install Python 3 first."
    exit 1
fi

# Install ChromaDB
echo "Installing ChromaDB..."
pip3 install chromadb

# Verify installation
echo -e "\nVerifying installation..."
python3 -c "import chromadb; print('✅ ChromaDB installed successfully')"

if [ $? -eq 0 ]; then
    echo -e "\n✅ All dependencies installed successfully!"
    echo "You can now use Memory Defragmenter with ChromaDB databases."
else
    echo -e "\n❌ ChromaDB installation verification failed."
    echo "Please check the error messages above."
fi
