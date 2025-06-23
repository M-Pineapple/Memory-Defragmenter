#!/bin/bash

# Simple script to create a zip for local Homebrew testing

echo "Creating test package for local Homebrew installation..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Working in: $TEMP_DIR"

# Copy the built app
APP_SOURCE="/Users/rogers/Library/Developer/Xcode/DerivedData/Memory_Defragmenter-dfddxkvubakavcagnmavmzqreiek/Build/Products/Release/Memory Defragmenter.app"
if [ -d "$APP_SOURCE" ]; then
    echo "Copying app bundle..."
    cp -R "$APP_SOURCE" "$TEMP_DIR/"
else
    echo "Error: App not found at $APP_SOURCE"
    echo "Please build the app in Release configuration first"
    exit 1
fi

# Create a zip file
OUTPUT_ZIP="/Users/rogers/GitHub/Memory Defragmenter/dist/MemoryDefragmenter-1.0.0.zip"
cd "$TEMP_DIR"
zip -r "$OUTPUT_ZIP" "Memory Defragmenter.app"

echo ""
echo "✅ Package created: $OUTPUT_ZIP"
echo ""

# Clean up
rm -rf "$TEMP_DIR"

# Show how to test locally
echo "To test the Homebrew installation locally:"
echo ""
echo "1. First, tap the local repository:"
echo "   brew tap rogers/memory-defragmenter file:///Users/rogers/GitHub/homebrew-memory-defragmenter"
echo ""
echo "2. Then install the cask:"
echo "   brew install --cask rogers/memory-defragmenter/memory-defragmenter"
echo ""
echo "Or install directly:"
echo "   brew install --cask /Users/rogers/GitHub/homebrew-memory-defragmenter/Casks/memory-defragmenter.rb"
