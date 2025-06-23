#!/bin/bash

# Build DMG for Memory Defragmenter distribution
# This creates a professional DMG installer for macOS

set -e

VERSION="${1:-1.0.0}"
APP_NAME="Memory Defragmenter"
DMG_NAME="MemoryDefragmenter-$VERSION"
VOLUME_NAME="Memory Defragmenter $VERSION"

echo "Building $APP_NAME DMG v$VERSION..."

# Build the app first
echo "Building Release version..."
xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath build \
    clean build

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Working in $TEMP_DIR"

# Copy app to temp directory
cp -R "build/Build/Products/Release/$APP_NAME.app" "$TEMP_DIR/"

# Create a symbolic link to Applications
ln -s /Applications "$TEMP_DIR/Applications"

# Copy additional files
cp README.md "$TEMP_DIR/"
cp LICENSE "$TEMP_DIR/"

# Create DMG background (optional - creates a simple one)
mkdir -p "$TEMP_DIR/.background"

# Create a simple Python installer script
cat > "$TEMP_DIR/Install Python Dependencies.command" << 'EOF'
#!/bin/bash
# Install Python dependencies for Memory Defragmenter

echo "Installing Python dependencies for Memory Defragmenter..."
echo ""

# Check if pip3 is installed
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 not found. Please install Python 3.10+ first."
    echo "You can install it with: brew install python@3.10"
    exit 1
fi

# Install dependencies
pip3 install numpy sentence-transformers

echo ""
echo "✅ Dependencies installed successfully!"
echo ""
echo "Press any key to close this window..."
read -n 1
EOF

chmod +x "$TEMP_DIR/Install Python Dependencies.command"

# Create the DMG
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_NAME.dmg"

# Clean up
rm -rf "$TEMP_DIR"

# Calculate SHA256
SHA256=$(shasum -a 256 "$DMG_NAME.dmg" | awk '{print $1}')

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "File: $DMG_NAME.dmg"
echo "SHA256: $SHA256"
echo ""
echo "This SHA256 can be used in the Homebrew Cask formula."

# Optionally sign and notarize (requires Apple Developer account)
echo ""
echo "Note: For distribution, you should sign and notarize the DMG:"
echo "  codesign --deep --force --verify --verbose --sign \"Developer ID Application: Your Name\" \"$DMG_NAME.dmg\""
echo "  xcrun notarytool submit \"$DMG_NAME.dmg\" --apple-id your@email.com --password app-specific-password --team-id TEAMID"
