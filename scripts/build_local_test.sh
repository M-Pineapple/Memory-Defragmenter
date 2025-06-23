#!/bin/bash

# Quick build script for local Homebrew testing

echo "Creating local release package for Homebrew testing..."

APP_PATH="/Users/rogers/Library/Developer/Xcode/DerivedData/Memory_Defragmenter-dfddxkvubakavcagnmavmzqreiek/Build/Products/Release/Memory Defragmenter.app"
VERSION="1.0.0"
TEMP_DIR="/tmp/memory-defragmenter-build"
OUTPUT_DIR="/Users/rogers/GitHub/Memory Defragmenter/dist"

# Clean and create directories
rm -rf "$TEMP_DIR" "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR"

# Copy the app
echo "Copying app bundle..."
cp -R "$APP_PATH" "$TEMP_DIR/"

# Copy additional files
cp "/Users/rogers/GitHub/Memory Defragmenter/README.md" "$TEMP_DIR/"
cp "/Users/rogers/GitHub/Memory Defragmenter/LICENSE" "$TEMP_DIR/"

# Create a simple installer script
cat > "$TEMP_DIR/install.sh" << 'EOF'
#!/bin/bash
cp -R "Memory Defragmenter.app" "/Applications/"
echo "Memory Defragmenter installed to /Applications"
EOF
chmod +x "$TEMP_DIR/install.sh"

# Create tarball
cd "$TEMP_DIR"
tar -czf "$OUTPUT_DIR/MemoryDefragmenter-$VERSION.tar.gz" .
cd -

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "Memory Defragmenter" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$OUTPUT_DIR/MemoryDefragmenter-$VERSION.dmg"

# Calculate checksums
cd "$OUTPUT_DIR"
TAR_SHA256=$(shasum -a 256 "MemoryDefragmenter-$VERSION.tar.gz" | awk '{print $1}')
DMG_SHA256=$(shasum -a 256 "MemoryDefragmenter-$VERSION.dmg" | awk '{print $1}')

echo ""
echo "✅ Build complete!"
echo ""
echo "Tarball SHA256: $TAR_SHA256"
echo "DMG SHA256: $DMG_SHA256"
echo ""
echo "Files created in: $OUTPUT_DIR"

# Clean up
rm -rf "$TEMP_DIR"
