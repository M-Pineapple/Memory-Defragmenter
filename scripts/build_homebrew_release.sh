#!/bin/bash

# Build script for Memory Defragmenter Homebrew distribution
# This script creates a release package for Homebrew installation

set -e

VERSION="${1:-1.0.0}"
RELEASE_DIR="release"
APP_NAME="Memory Defragmenter"
BUNDLE_NAME="$APP_NAME.app"

echo "Building Memory Defragmenter v$VERSION for Homebrew..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Build the macOS app
echo "Building macOS app..."
xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath build \
    -destination "platform=macOS" \
    clean build

# Copy the app bundle
echo "Copying app bundle..."
cp -R "build/Build/Products/Release/$BUNDLE_NAME" "$RELEASE_DIR/"

# Build the CLI tool (if exists)
if [ -f "Package.swift" ]; then
    echo "Building CLI tool..."
    swift build --configuration release
    cp .build/release/memory-defragmenter "$RELEASE_DIR/" 2>/dev/null || true
fi

# Copy necessary files
echo "Copying additional files..."
cp README.md "$RELEASE_DIR/"
cp LICENSE "$RELEASE_DIR/"
cp -R homebrew "$RELEASE_DIR/"

# Create Python requirements file
cat > "$RELEASE_DIR/requirements.txt" << EOF
numpy>=1.21.0
sentence-transformers>=2.0.0
EOF

# Create installation script
cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash
# Installation script for Memory Defragmenter

INSTALL_DIR="/Applications"
APP_NAME="Memory Defragmenter.app"

echo "Installing Memory Defragmenter..."

# Check if running on macOS 15+
if ! sw_vers -productVersion | grep -E "^1[5-9]\.|^[2-9][0-9]\." > /dev/null; then
    echo "Error: Memory Defragmenter requires macOS 15.0 (Sequoia) or later"
    exit 1
fi

# Copy app to Applications
if [ -d "$APP_NAME" ]; then
    echo "Installing $APP_NAME to $INSTALL_DIR..."
    cp -R "$APP_NAME" "$INSTALL_DIR/"
    echo "✅ App installed successfully!"
else
    echo "Error: $APP_NAME not found"
    exit 1
fi

# Install Python dependencies
if command -v pip3 &> /dev/null; then
    echo "Installing Python dependencies..."
    pip3 install -r requirements.txt
else
    echo "⚠️  Warning: pip3 not found. Please install Python dependencies manually:"
    echo "   pip3 install -r requirements.txt"
fi

echo ""
echo "Installation complete! 🎉"
echo "You can now launch Memory Defragmenter from your Applications folder."
EOF

chmod +x "$RELEASE_DIR/install.sh"

# Create tarball
echo "Creating release tarball..."
cd "$RELEASE_DIR"
tar -czf "../MemoryDefragmenter-$VERSION.tar.gz" .
cd ..

# Calculate SHA256
echo "Calculating SHA256..."
SHA256=$(shasum -a 256 "MemoryDefragmenter-$VERSION.tar.gz" | awk '{print $1}')

echo ""
echo "✅ Build complete!"
echo ""
echo "Release package: MemoryDefragmenter-$VERSION.tar.gz"
echo "SHA256: $SHA256"
echo ""
echo "Update the Homebrew formula with this SHA256 hash."

# Clean up
rm -rf "$RELEASE_DIR"
